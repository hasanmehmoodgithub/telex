
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentTile extends StatefulWidget {
  final VoidCallback onTabDelete;
  final Map<String, dynamic> comment;
  final String currentUserId;
  final String commentId;

  const CommentTile({
    Key? key,
    required this.comment,
    required this.currentUserId,
    required this.commentId,
    required this.onTabDelete,
  }) : super(key: key);

  @override
  _CommentTileState createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  String? userImageUrl;
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserInfo() async {
    String userId = widget.comment['createdBy']; // Assuming createdBy stores user ID
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userImageUrl = userSnapshot['imageUrl'];
          userName = userSnapshot['name'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Delete comment function


  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(userImageUrl ?? ''),
      ),
      title: Text(
        userName ?? '----- ',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(widget.comment['content']),
      trailing: widget.comment['createdBy'] == widget.currentUserId
          ? IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: widget.onTabDelete,
      )
          : null,
    );
  }
}

