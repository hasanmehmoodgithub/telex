import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/groups/Group_Feed_Screen.dart';
import 'package:telex/screens/groups/ViewGroupScreen.dart';
class AllGroupsScreen extends StatefulWidget {
  const AllGroupsScreen({super.key});

  @override
  _AllGroupsScreenState createState() => _AllGroupsScreenState();
}

class _AllGroupsScreenState extends State<AllGroupsScreen> {
  late Future<List<Map<String, dynamic>>> _allGroupsFuture;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID

  @override
  void initState() {
    super.initState();
    _allGroupsFuture = _fetchAllGroups();
  }

  Future<List<Map<String, dynamic>>> _fetchAllGroups() async {
    // Fetching all groups from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('groups').get();

    // Fetch the joined groups to filter them out
    QuerySnapshot joinedGroupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .get();

    // Create a list of joined group IDs
    List<String> joinedGroupIds = joinedGroupsSnapshot.docs.map((doc) => doc.id).toList();

    // Filter out the joined groups
    return querySnapshot.docs
        .where((doc) => !joinedGroupIds.contains(doc.id)) // Exclude joined groups
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _allGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading groups"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget();
          }

          final allGroups = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allGroups.length,
            itemBuilder: (context, index) {
              final group = allGroups[index];
              return _buildAllGroupCard(group, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildAllGroupCard(Map<String, dynamic> group, BuildContext context) {
    return InkWell(
      onLongPress: (){
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(  group['name']),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Image.network(group["groupUrl"], height: 150),
                    const SizedBox(height: 10,),
                    Text(
                      group['description'],
                      style: const TextStyle(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

      },
      onTap: () {
        bool isPrivate = group['isPrivate'] ?? false;
        if(isPrivate)
        { ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please join the group to see posts."),
            duration: Duration(seconds: 3),
          ),
        );
        return;

        }
        final groupId = group['id'] as String;
        log(groupId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewGroupScreen(groupId: groupId),
          ),
        );
      },
      child: Container(
        height: 250,
        width: 200,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.network(group["groupUrl"], height: 150),
                Text(
                  group['name'],
                  style: const TextStyle(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  group['description'],
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                ElevatedButton(
                  onPressed: () {
                    joinGroup(group['id']);
                  },
                  child: const Text("Join"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            title: Container(
              height: 20,
              width: double.infinity,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 14,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text("No groups available."),
    );
  }

  Future<void>  joinGroup(String groupId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUserId]), // Replace with the actual user ID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have joined the group!")),
    );

    setState(() {
      _allGroupsFuture = _fetchAllGroups();
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GroupFeedScreen(),
      ),
    );
  }
}
