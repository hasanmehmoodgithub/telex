import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/groups/CreatePostScreen.dart';

class ViewGroupScreen extends StatefulWidget {
  final String groupId;

  ViewGroupScreen({required this.groupId});

  @override
  _ViewGroupScreenState createState() => _ViewGroupScreenState();
}

class _ViewGroupScreenState extends State<ViewGroupScreen> {
  late Future<Map<String, dynamic>?> _groupDetailsFuture;
  late Future<List<Map<String, dynamic>>> _postsFuture;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _groupDetailsFuture = _fetchGroupDetails();
    _postsFuture = _fetchPosts();
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

      appBar: AppBar(title: Text("Group Details")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _groupDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading group details"));
          } else if (!snapshot.hasData) {
            return Center(child: Text("Group not found"));
          }

          final group = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                groupBannerWidget(group),
                FetchGroupPosts(groupId: widget.groupId),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
     floatingActionButton: _isJoined ?  FloatingActionButton(
        onPressed:  _createPost,// Only allow posting if user has joined the group
        child:  Icon(Icons.add),
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
          SnackBar(content: Text("The creator cannot leave the group.")),
        );
      } else {
        // Proceed to remove the user from the members list
        await _firestore.collection('groups').doc(groupId).update({
          'members': FieldValue.arrayRemove([userId]), // Remove user ID from the members list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have left the group successfully.")),
        );

        print("User $userId has left the group $groupId.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group does not exist.")),
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  group['description'],
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          _isJoined?   MaterialButton(onPressed: (){
            leaveGroup(context,widget.groupId,FirebaseAuth.instance.currentUser!.uid);
          },child: Text("Leave Group"),)
              :SizedBox()

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
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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

  FetchGroupPosts({required this.groupId});

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
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No posts available."));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
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

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final String groupId;
  final String postId;

  const PostWidget({
    Key? key,
    required this.post,
    required this.groupId,
    required this.postId,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    isLiked = widget.post['likes']?.contains(currentUser?.uid) ?? false;
    likeCount = widget.post['likeCount'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            SizedBox(height: 12.0),
            _buildPostTitle(),
            SizedBox(height: 8.0),
            _buildPostDescription(),
            if (widget.post['imageUrl'] != null) _buildPostImage(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Row _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.post['userImage'] ?? ''),
          radius: 24,
        ),
        SizedBox(width: 8.0),
        Text(
          widget.post['createdBy'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Text _buildPostTitle() {
    return Text(
      widget.post['title'],
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Text _buildPostDescription() {
    return Text(
      widget.post['description'],
      style: TextStyle(fontSize: 14, color: Colors.black87),
    );
  }

  ClipRRect _buildPostImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Image.network(
        widget.post['imageUrl'],
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Row _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleLike(),
            ),
            Text(likeCount.toString()),
            SizedBox(width: 16.0),
            IconButton(
              icon: Icon(Icons.comment),
              onPressed: () {
                _showComments(context);
              },
            ),
            Text(widget.post['commentCount']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(widget.postId);
    final postSnapshot = await postRef.get();

    if (!postSnapshot.exists) return;

    List<dynamic> likes = postSnapshot['likes'] ?? [];
    int currentLikeCount = postSnapshot['likeCount'] ?? 0;

    if (isLiked) {
      // User is unliking the post
      likes.remove(currentUser.uid);
      likeCount = currentLikeCount - 1;
    } else {
      // User is liking the post
      likes.add(currentUser.uid);
      likeCount = currentLikeCount + 1;
    }

    await postRef.update({
      'likes': likes,
      'likeCount': likeCount,
    });

    setState(() {
      isLiked = !isLiked;
    });
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CommentsBottomSheet(postId: widget.postId, groupId: widget.groupId);
      },
    );
  }
}




class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String groupId;

  CommentsBottomSheet({required this.postId, required this.groupId});

  @override
  _CommentsBottomSheetState createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final commentData = {
        'content': _commentController.text,
        'createdAt': Timestamp.now(),
        'createdBy': currentUserId,
      };

      // Add comment to Firestore
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add(commentData);

      // Update comment count in the post
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(widget.postId)
          .update({
        'commentCount': FieldValue.increment(1),
      });

      // Clear the input field
      _commentController.clear();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    // Delete comment from Firestore
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    // Update comment count in the post
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(widget.postId)
        .update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.6, // Set height for the bottom sheet
      child: Column(
        children: [
          Text(
            "Comments",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No comments available."));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;

                    return ListTile(
                      title: Text(comment['content']),
                      subtitle: Text(comment['createdBy'] ?? 'Unknown user'),
                      trailing: comment['createdBy'] == currentUserId // Check if the current user is the author
                          ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteComment(commentId);
                        },
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Add a comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

