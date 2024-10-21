import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telex/screens/groups/widgets/CommentsBottomSheet.dart';
import 'package:telex/screens/home/user_profile_screen.dart';
import 'package:telex/utils/app_funtions.dart';

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
  String? userImageUrl;
  String? userName;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    isLiked = widget.post['likes']?.contains(currentUser?.uid) ?? false;
    likeCount = widget.post['likeCount'] ?? 0;
    _fetchUserInfo();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserInfo() async {
    String userId = widget.post['createdBy']; // Assuming createdBy stores user ID
    log(userId.toString(), name: "test");
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        log('userSnapshot.exists');
        setState(() {
          userImageUrl = userSnapshot['imageUrl'];
          userName = userSnapshot['name'];
          log(userName.toString(), name: "test");
          log(userImageUrl.toString(), name: "test");
        });
      }
    } catch (e) {
      log(e.toString(), name: "test");
      log('Error fetching user data: $e');
    }
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

  Widget _buildUserInfo() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserPost = currentUser?.uid == widget.post['createdBy'];
    bool  isAnonymous= widget.post['isAnonymous'];
    return Row(
      children: [
        InkWell(
          onTap: (){
            Navigator.of(context).push(
          MaterialPageRoute(
           builder: (_) => UserProfileScreen(profileUserId: widget.post['createdBy'],),
          ),
      );
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(isAnonymous?"https://cdn4.iconfinder.com/data/icons/people-14/24/Anonymous-2-512.png":userImageUrl ?? ''),
            radius: 24,
          ),
        ),
        SizedBox(width: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              isAnonymous?"Anonymous":  userName ?? '-----',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              getTimeAgo(widget.post["createdDate"]),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Spacer(),
        if (isCurrentUserPost) // Show delete button if the current user is the post creator
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deletePost(),
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
      child: CachedNetworkImage(
        imageUrl: widget.post['imageUrl'],
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[300], // Grey placeholder
          height: 150.0, // Adjust height if needed
          child: Center(child: CircularProgressIndicator()), // Optional loading spinner
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300], // Grey background for error
          height: 150.0, // Adjust height if needed
          child: Icon(
            Icons.error, // Error icon
            color: Colors.red,
          ),
        ),
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

  Future<void> _deletePost() async {
    final postRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(widget.postId);

    // Show a confirmation dialog before deleting
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await postRef.delete();
        // Optionally, you could also show a SnackBar to confirm deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        log('Error deleting post: $e');
        // Optionally, show an error message
      }
    }
  }
}

// import 'dart:developer';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:telex/screens/groups/widgets/CommentsBottomSheet.dart';
// import 'package:telex/screens/home/user_profile_screen.dart';
// import 'package:telex/utils/app_funtions.dart';
//
// class PostWidget extends StatefulWidget {
//   final Map<String, dynamic> post;
//   final String groupId;
//   final String postId;
//
//   const PostWidget({
//     Key? key,
//     required this.post,
//     required this.groupId,
//     required this.postId,
//   }) : super(key: key);
//
//   @override
//   _PostWidgetState createState() => _PostWidgetState();
// }
//
// class _PostWidgetState extends State<PostWidget> {
//   bool isLiked = false;
//   int likeCount = 0;
//   String? userImageUrl;
//   String? userName;
//   @override
//   void initState() {
//     super.initState();
//     final currentUser = FirebaseAuth.instance.currentUser;
//     isLiked = widget.post['likes']?.contains(currentUser?.uid) ?? false;
//     likeCount = widget.post['likeCount'] ?? 0;
//     _fetchUserInfo();
//   }
//   // Fetch user data from Firestore
//   Future<void> _fetchUserInfo() async {
//     String userId = widget.post['createdBy']; // Assuming createdBy stores user ID
//     log(userId.toString(),name: "test");
//     try {
//       DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();
//
//       if (userSnapshot.exists) {
//         log('userSnapshot.exists');
//         setState(() {
//           userImageUrl = userSnapshot['imageUrl'];
//           userName = userSnapshot['name'];
//           log(userName.toString(),name: "test");
//           log(userImageUrl.toString(),name:"test");
//         });
//       }
//     } catch (e) {
//       log(e.toString(),name: "test");
//       log('Error fetching user data: $e');
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16.0),
//       ),
//       margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildUserInfo(),
//             SizedBox(height: 12.0),
//             _buildPostTitle(),
//             SizedBox(height: 8.0),
//             _buildPostDescription(),
//             if (widget.post['imageUrl'] != null) _buildPostImage(),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUserInfo() {
//     return InkWell(
//       onTap: (){
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => UserProfileScreen(profileUserId: widget.post['createdBy'],),
//           ),
//         );
//
//         },
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundImage: NetworkImage(userImageUrl ?? ''),
//             radius: 24,
//           ),
//           SizedBox(width: 8.0),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [   Text(
//             userName ?? '-----',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//             Text(   getTimeAgo( widget.post["createdDate"]), style: TextStyle(fontSize: 12,color: Colors.grey)),],)
//
//         ],
//       ),
//     );
//   }
//
//   Text _buildPostTitle() {
//     return Text(
//       widget.post['title'],
//       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//     );
//   }
//
//   Text _buildPostDescription() {
//     return Text(
//       widget.post['description'],
//       style: TextStyle(fontSize: 14, color: Colors.black87),
//     );
//   }
//
//   ClipRRect _buildPostImage() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16.0),
//       child: CachedNetworkImage(
//         imageUrl: widget.post['imageUrl'],
//         fit: BoxFit.cover,
//         width: double.infinity,
//         placeholder: (context, url) => Container(
//           color: Colors.grey[300], // Grey placeholder
//           height: 150.0, // Adjust height if needed
//           child: Center(child: CircularProgressIndicator()), // Optional loading spinner
//         ),
//         errorWidget: (context, url, error) => Container(
//           color: Colors.grey[300], // Grey background for error
//           height: 150.0, // Adjust height if needed
//           child: Icon(
//             Icons.error, // Error icon
//             color: Colors.red,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Row _buildActionButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             IconButton(
//               icon: Icon(
//                 isLiked ? Icons.favorite : Icons.favorite_border,
//                 color: isLiked ? Colors.red : Colors.grey,
//               ),
//               onPressed: () => _toggleLike(),
//             ),
//             Text(likeCount.toString()),
//             SizedBox(width: 16.0),
//             IconButton(
//               icon: Icon(Icons.comment),
//               onPressed: () {
//                 _showComments(context);
//               },
//             ),
//             Text(widget.post['commentCount']?.toString() ?? '0'),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Future<void> _toggleLike() async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;
//
//     final postRef = FirebaseFirestore.instance
//         .collection('groups')
//         .doc(widget.groupId)
//         .collection('posts')
//         .doc(widget.postId);
//     final postSnapshot = await postRef.get();
//
//     if (!postSnapshot.exists) return;
//
//     List<dynamic> likes = postSnapshot['likes'] ?? [];
//     int currentLikeCount = postSnapshot['likeCount'] ?? 0;
//
//     if (isLiked) {
//       // User is unliking the post
//       likes.remove(currentUser.uid);
//       likeCount = currentLikeCount - 1;
//     } else {
//       // User is liking the post
//       likes.add(currentUser.uid);
//       likeCount = currentLikeCount + 1;
//     }
//
//     await postRef.update({
//       'likes': likes,
//       'likeCount': likeCount,
//     });
//
//     setState(() {
//       isLiked = !isLiked;
//     });
//   }
//
//   void _showComments(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return CommentsBottomSheet(postId: widget.postId, groupId: widget.groupId);
//       },
//     );
//   }
// }