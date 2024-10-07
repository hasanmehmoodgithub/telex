import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/groups/CreatePostScreen.dart';
import 'package:telex/screens/groups/widgets/PostWidget.dart';

class ViewGroupScreen extends StatefulWidget {
  final String groupId;

  ViewGroupScreen({super.key, required this.groupId});

  @override
  ViewGroupScreenState createState() => ViewGroupScreenState();
}

class ViewGroupScreenState extends State<ViewGroupScreen> {
  late Future<Map<String, dynamic>?> _groupDetailsFuture;

  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _groupDetailsFuture = _fetchGroupDetails();

  }

  Future<Map<String, dynamic>?> _fetchGroupDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      _isJoined = (data['members'] as List).contains(FirebaseAuth.instance.currentUser?.uid); // Use actual user ID
      log(_isJoined.toString(),name: "_isJoined");
      setState(() {
        _isJoined = (data['members'] as List).contains(FirebaseAuth.instance.currentUser?.uid); // Use actual user ID
        log(_isJoined.toString(),name: "_isJoined");
      });
      return data;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text("Group Details")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _groupDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading group details"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Group not found"));
          }

          final group = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                groupBannerWidget(group),
                FetchGroupPosts(groupId: widget.groupId),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
     floatingActionButton: _isJoined ?  FloatingActionButton(
        onPressed:  _createPost,// Only allow posting if user has joined the group
        child:  const Icon(Icons.add),
      ):null,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _createPost,
      //   child: Icon(Icons.add),
      // ),
    );
  }
  Future<void> leaveGroup(BuildContext context, String groupId, String userId) async {
    // Fetch group data to check who created it
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    DocumentSnapshot groupSnapshot = await _firestore.collection('groups').doc(groupId).get();

    if (groupSnapshot.exists) {
      // Extract creator ID and member list
      String createdBy = groupSnapshot['createdBy'];
      List<dynamic> members = groupSnapshot['members']; // Assuming you have a 'members' field

      // Check if the user is the creator
      if (userId == createdBy) {
        // The creator cannot leave the group
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The creator cannot leave the group.")),
        );
      } else {
        // Proceed to remove the user from the members list
        await _firestore.collection('groups').doc(groupId).update({
          'members': FieldValue.arrayRemove([userId]), // Remove user ID from the members list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have left the group successfully.")),
        );
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, "/groups");

        log("User $userId has left the group $groupId.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group does not exist.")),
      );
    }
  }
  SizedBox groupBannerWidget(Map<String, dynamic> group) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(group['groupUrl'] ?? 'https://via.placeholder.com/200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  group['description'],
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          _isJoined?   Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButton(
                color: Colors.white.withOpacity(0.3),
                onPressed: (){leaveGroup(context,widget.groupId,FirebaseAuth.instance.currentUser!.uid);},
                  child: const Text("Leave Group")),
            ),
          )
              :const SizedBox()

        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              height: 80,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Future<void> _createPost() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostScreen(groupId: widget.groupId)),
    );
  }
}

class FetchGroupPosts extends StatelessWidget {
  final String groupId;

  FetchGroupPosts({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("\n\nNo posts available."));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            return PostWidget(post: post, groupId: groupId, postId: postId);
          },
        );
      },
    );
  }
}






