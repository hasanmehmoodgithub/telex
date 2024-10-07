import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telex/screens/groups/CreateGroupScreen.dart';
import 'package:telex/screens/groups/widgets/AllGroupsScreen.dart';
import 'package:telex/screens/groups/widgets/JoinedGroupListView.dart';
import 'package:telex/screens/groups/widgets/JoinedGroupPosts.dart';
import 'package:telex/screens/groups/widgets/PostWidget.dart';


class GroupFeedScreen extends StatefulWidget {
  const GroupFeedScreen({super.key});

  @override
  GroupFeedScreenState createState() => GroupFeedScreenState();
}

class GroupFeedScreenState extends State<GroupFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Feed'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text("Joined Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              JoinedGroupListView(),
              SizedBox(height: 20),
              Text("Trending Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              AllGroupsScreen(),
              SizedBox(height: 20),
              Text("Posts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // Wrapping the posts list in SizedBox to give a fixed height
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, // Adjust this height as needed
                child: JoinedGroupPosts(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(),
      ),
    );
  }
}


