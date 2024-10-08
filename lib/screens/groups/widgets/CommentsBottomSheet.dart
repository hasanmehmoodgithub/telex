
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telex/screens/groups/widgets/CommentTile.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String groupId;

  CommentsBottomSheet({super.key, required this.postId, required this.groupId});

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

                    return CommentTile(comment: comment,commentId: commentId,currentUserId:comment['createdBy'] ,onTabDelete: (){_deleteComment(commentId);});

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
  String? userImageUrl;
  String? userName;
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
  Row _buildUserInfo(String userId) {

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(userImageUrl ?? ''),
          radius: 24,
        ),
        SizedBox(width: 8.0),
        Text(
          userName ?? '-----',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

}
