import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/groups/ViewGroupScreen.dart';

class JoinedGroupListView extends StatefulWidget {
  const JoinedGroupListView({super.key});

  @override
  _JoinedGroupListViewState createState() => _JoinedGroupListViewState();
}

class _JoinedGroupListViewState extends State<JoinedGroupListView> {
  late Future<List<Map<String, dynamic>>> _joinedGroupsFuture;

  @override
  void initState() {
    super.initState();
    _joinedGroupsFuture = _fetchJoinedGroups();
  }

  Future<List<Map<String, dynamic>>> _fetchJoinedGroups() async {
    final userId = FirebaseAuth.instance.currentUser?.uid; // Use the current user's ID
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _joinedGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading groups"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget();
          }

          final joinedGroups = snapshot.data!;
          return ListView.builder(

            scrollDirection: Axis.horizontal,
            itemCount: joinedGroups.length,
            itemBuilder: (context, index) {
              final group = joinedGroups[index]; // Fixed to use the correct index
              return _buildGroupCard(group, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, BuildContext context) {
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
        final groupId = group['id'] as String;
        log(groupId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewGroupScreen(groupId: groupId),
          ),
        );
      },
      child: groupItemCard(group),
    );
  }

  SizedBox groupItemCard(Map<String, dynamic> group) {
    return SizedBox(
      height: 160,
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: group["groupUrl"] ??
                    "https://media.istockphoto.com/id/1223631367/vector/multicultural-group-of-people-is-standing-together-team-of-colleagues-students-happy-men-and.jpg?s=612x612&w=0&k=20&c=9Mwxpq9gADCuEyvFxUdmNhlQea5PED-jwCmqtfgdXhU=",
                height: 100,
                width: 200,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()), // Shows a loader while the image is loading
                errorWidget: (context, url, error) => Icon(Icons.error), // Shows error icon if image fails to load
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5, // Show 5 shimmer items
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
      child: Text("You have not joined any groups yet."),
    );
  }
}
