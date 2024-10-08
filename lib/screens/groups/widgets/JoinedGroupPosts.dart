
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:telex/screens/groups/widgets/PostWidget.dart';

class JoinedGroupPosts extends StatefulWidget {
  const JoinedGroupPosts({super.key});

  @override
  _JoinedGroupPostsState createState() => _JoinedGroupPostsState();
}

class _JoinedGroupPostsState extends State<JoinedGroupPosts> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getTopPostsAcrossGroups() async {
    try {
      log("try", name: "getTopPostsAcrossGroups");
      // Step 1: Get all groups

      final userId = FirebaseAuth.instance.currentUser?.uid; // Use the current user's ID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();



      //QuerySnapshot groupSnapshot = await _firestore.collection('groups').get();
      // List to store posts
      List<Map<String, dynamic>> allPosts = [];

      // Step 2: Iterate through each group's posts subcollection
      for (var groupDoc in querySnapshot.docs) {
        String groupId = groupDoc.id;
        log("$groupId", name: "getTopPostsAcrossGroups");
        // Step 3: Fetch the first 2 posts from the group's posts subcollection
        QuerySnapshot postSnapshot = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('posts')
            .orderBy('createdDate', descending: true) // Order by createdDate
            .limit(2) // Limit to 2 posts per group
            .get();

        // Add the posts from the current group to the allPosts list
        allPosts.addAll(postSnapshot.docs.map((doc) {
          log("$postSnapshot", name: "getTopPostsAcrossGroups");
          return {
            'groupId': groupId, // Include groupId here
            'postId': doc.id, // Include postId here
            ...doc.data() as Map<String, dynamic>
          };
        }).toList());

        // Break the loop if we already have 2 posts
        if (allPosts.length >= 3) break;
      }
      log("$allPosts", name: "getTopPostsAcrossGroups");

      // Return only the first 2 posts (in case multiple groups are fetched)
      return allPosts.take(2).toList();
    } catch (e) {
      print("Error fetching posts: $e");
      log("$e", name: "getTopPostsAcrossGroups");
      return [];
    }
  }
  void _fetchPosts() async {

    final posts = await getTopPostsAcrossGroups();
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : _posts.isEmpty
        ? Center(child: Text('No posts available'))
        : ListView.builder(
   //   physics: NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        log(post.toString(), name: "post");

        return PostWidget(
          post: post,
          groupId: post['groupId'],
          postId: post['postId'],
        );
      },
    );
  }
}
