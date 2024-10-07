import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/groups/CreateGroupScreen.dart';
import 'ViewGroupScreen.dart';

class GroupFeedScreen extends StatefulWidget {
  @override
  _GroupFeedScreenState createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Feed'),
      ),
      body: ListView(
        children: [
          JoinedGroupListView(),
          AllGroupsScreen(),
          LatestPostsFromJoinedGroups()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        child: Icon(Icons.add),
      ),
    );
  }
}

class JoinedGroupListView extends StatefulWidget {
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
    return Container(
      height: 260,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _joinedGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading groups"));
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
                      SizedBox(height: 10,),
                      Text(
                        group['description'],
                        style: TextStyle(fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Close'),
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
        _navigateToViewGroup(groupId, context);
      },
      child: groupItemCard(group),
    );
  }

  Container groupItemCard(Map<String, dynamic> group) {
    return Container(
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
                style: TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                group['description'],
                style: TextStyle(fontSize: 12),
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
    return Center(
      child: Text("You have not joined any groups yet."),
    );
  }
}

class AllGroupsScreen extends StatefulWidget {
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
            return Center(child: Text("Error loading groups"));
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
                    SizedBox(height: 10,),
                    Text(
                      group['description'],
                      style: TextStyle(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
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
            SnackBar(
              content: Text("Please join the group to see posts."),
              duration: Duration(seconds: 3),
            ),
          );
            return;

          }
        final groupId = group['id'] as String;
        log(groupId);
        _navigateToViewGroup(groupId, context);
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
                  style: TextStyle(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  group['description'],
                  style: TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                ElevatedButton(
                  onPressed: () {
                    _joinGroup(group['id']);
                  },
                  child: Text("Join"),
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
    return Center(
      child: Text("No groups available."),
    );
  }

  Future<void>  _joinGroup(String groupId) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUserId]), // Replace with the actual user ID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You have joined the group!")),
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

void _navigateToViewGroup(String groupId, BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ViewGroupScreen(groupId: groupId),
    ),
  );
}




class LatestPostsFromJoinedGroups extends StatefulWidget {
  @override
  _LatestPostsFromJoinedGroupsState createState() =>
      _LatestPostsFromJoinedGroupsState();
}

class _LatestPostsFromJoinedGroupsState
    extends State<LatestPostsFromJoinedGroups> {
  late Future<List<Map<String, dynamic>>> _latestPostsFuture;

  @override
  void initState() {
    super.initState();
    _latestPostsFuture = _fetchLatestPostsFromJoinedGroups();
  }

  Future<List<Map<String, dynamic>>> _fetchLatestPostsFromJoinedGroups() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      log('User is not authenticated');
      throw Exception("User is not authenticated");
    }

    List<Map<String, dynamic>> result = [];

    try {
      // Fetching joined groups
      QuerySnapshot groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();

      log('User is a member of ${groupsSnapshot.docs.length} groups');

      // Iterate through each group to fetch the latest post
      for (var groupDoc in groupsSnapshot.docs) {
        String groupId = groupDoc.id;

        // Fetch the latest post for the current group
        Map<String, dynamic>? latestPost = await _fetchLatestPostForGroup(groupId);

        if (latestPost != null) {
          result.add({
            'groupId': groupId,
            ...latestPost,
          });
        }
      }
    } catch (e) {
      log('Error fetching latest posts: $e');
      throw e;
    }

    return result;
  }

  Future<Map<String, dynamic>?> _fetchLatestPostForGroup(String groupId) async {
    try {
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('groups')           // Collection of groups
          .doc(groupId)                  // Document of the specific group
          .collection('posts')           // Sub-collection of posts for the group
          .orderBy('createdAt', descending: true) // Order by creation date
          .limit(1)                     // Get only the latest post
          .get();

      log('Found ${postsSnapshot.docs.length} posts for group $groupId');

      if (postsSnapshot.docs.isNotEmpty) {
        return {
          'id': postsSnapshot.docs[0].id,
          ...postsSnapshot.docs[0].data() as Map<String, dynamic>,
        };
      }
    } catch (e) {
      log('Error fetching posts for group $groupId: $e');
      throw e;
    }

    return null; // No post found for this group
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _latestPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading posts: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No posts available."));
          }

          final posts = snapshot.data!;
          return SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostItem(post);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return SizedBox(
      height: 200,
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(post['description'] ?? 'No description'),
              SizedBox(height: 8),
              post['imageUrl'] != null
                  ? Image.network(post['imageUrl'])
                  : SizedBox.shrink(),
              SizedBox(height: 8),
              Text("Created by: ${post['createdBy'] ?? 'Anonymous'}"),
              SizedBox(height: 4),
              Text("Created at: ${post['createdAt']?.toDate().toString() ?? ''}"),
              SizedBox(height: 4),
             // Text("Likes: ${post['likes']?.length ?? 0}"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 3, // Show 3 shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(height: 20, color: Colors.white),
                  SizedBox(height: 8),
                  Container(height: 14, color: Colors.white),
                  SizedBox(height: 16),
                  Container(height: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
