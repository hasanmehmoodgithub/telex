import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:telex/common/responsive_widget.dart';
import 'package:telex/screens/home/user_profile_screen.dart';
import 'package:telex/utils/app_funtions.dart';
import 'dart:io';
import 'package:timeago/timeago.dart' as timeago;
import 'package:telex/utils/media_query_extension.dart';

class GroupPostScreen extends StatefulWidget {
  final String groupId;

  const GroupPostScreen({required this.groupId, Key? key}) : super(key: key);

  @override
  _GroupPostScreenState createState() => _GroupPostScreenState();
}

class _GroupPostScreenState extends State<GroupPostScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _imageFile;
  final _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();
  bool _isAnonymous = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Posts'),
      ),
      body: ResponsiveWidget(
        maxWidth: 600.0,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('groups')
              .doc(widget.groupId)
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching posts.'));
            }

            final posts = snapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Post',
      ),
    );
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<int> _getCommentCount(String postId) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();
    return snapshot.size; // Returns the number of comments
  }

  // Create a post in Firestore
  Future<void> _createPost(String content, bool isAnonymous) async {
    final user = _auth.currentUser;
    if (user != null) {
      String? imageUrl;

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref('group_posts/${widget.groupId}')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .add({
        'content': content,
        'imageUrl': imageUrl ?? '',
        'createdBy': isAnonymous ? null : user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': {},
        'comments': [],
        'isAnonymous': isAnonymous,
      });

      _contentController.clear();
      setState(() {
        _imageFile = null;
        _isAnonymous = false;
      });
    }
  }

  // Like/unlike a post
  Future<void> _toggleLikePost(String postId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final postDoc = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .get();
      final likes = postDoc['likes'] as Map<String, dynamic>? ?? {};

      if (likes.containsKey(user.uid)) {
        likes.remove(user.uid); // Unlike
      } else {
        likes[user.uid] = true; // Like
      }

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .update({'likes': likes});
    }
  }

  // Fetch user details
  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data();
  }

  // Show create post dialog
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Post'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _imageFile != null
                    ? Column(
                        children: [
                          Image.file(_imageFile!, height: 150),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                            child: Text('Remove Image'),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: Icon(Icons.image, size: 40),
                        onPressed: _pickImage,
                      ),
                SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Post Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Post Anonymously'),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text('Post'),
              onPressed: () {
                final content = _contentController.text.trim();
                if (content.isNotEmpty) {
                  _createPost(content, _isAnonymous);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(QueryDocumentSnapshot post) {
    final postId = post.id;
    final isAnonymous = post['isAnonymous'] ?? false;
    final likes = post['likes'] as Map<String, dynamic>? ?? {};

    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAnonymous)
              FutureBuilder<Map<String, dynamic>?>(
                future: _getUserDetails(post['createdBy']),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (userSnapshot.hasError || userSnapshot.data == null) {
                    return Text('User not found');
                  }
                  final userData = userSnapshot.data!;
                  return Row(
                    children: [
                      InkWell(
                        onTap:(){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                profileUserId: post['createdBy'],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                              userData['imageUrl'] ?? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcbYYoQtVusBGIbEgOo3dyyL2k2AAFqSu6lDm0XJEQ-5kX3mTKqO5oRZoNoyPMr9-Ht2I&usqp=CAU'
                          ),
                        ),
                      ),

                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(userData['name'] ?? 'Anonymous',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(   getTimeAgo(post['createdAt']), style: TextStyle(fontSize: 12,color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                },
              )
            else
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(
                      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjsXjSVUT5U6QA8Gwz61r2g_EBneRk-sBbPw&s",
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Anonymous', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(   getTimeAgo(post['createdAt']), style: TextStyle(fontSize: 12,color: Colors.grey)),
                    ],
                  ),
                ],
              ),




            SizedBox(height: 8,),
            Text(post['content'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 8,),
            if (post['imageUrl'].isNotEmpty)
              CachedNetworkImage(
                imageUrl:
                    post['imageUrl'] ?? '', // Replace with actual image URL
                placeholder: (context, url) =>  Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)),color: Colors.grey[300],),
                  height: 400,
                  width: context.screenWidth,
                   // Placeholder color for error
                  child:
                  const Center(child: CircularProgressIndicator(),), // Error icon
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)),color: Colors.grey[300],),
                  height: 400,
                  width: context.screenWidth,

                  child:
                      const Icon(Icons.error, color: Colors.red), // Error icon
                ),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    likes.containsKey(_auth.currentUser?.uid)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: likes.containsKey(_auth.currentUser?.uid)
                        ? Colors.red
                        : Colors.grey,
                  ),
                  onPressed: () => _toggleLikePost(postId),
                ),
                Text('${likes.length}'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                            postId: postId, groupId: widget.groupId),
                      ),
                    );
                  },
                  child: FutureBuilder<int>(
                    future: _getCommentCount(postId),
                    builder: (context, commentSnapshot) {
                      if (commentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentsScreen(
                                        postId: postId,
                                        groupId: widget.groupId),
                                  ),
                                );
                              },
                            ),
                            Text('...'), // Placeholder while loading count
                          ],
                        );
                      }
                      if (commentSnapshot.hasError) {
                        return Text('0');
                      }

                      final commentCount = commentSnapshot.data ?? 0;

                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.mode_comment_outlined,color:   Colors.grey,),
                            onPressed: () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) => CommentsScreen(
                                      postId: postId, groupId: widget.groupId));


                            },
                          ),
                          Text('$commentCount'), // Comment count
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// CommentsScreen (You can modify it based on your requirements)
class CommentsScreen extends StatefulWidget {
  final String postId;
  final String groupId;

  const CommentsScreen({required this.postId, required this.groupId, Key? key})
      : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new comment
  Future<void> _addComment(String commentContent) async {
    final user = _auth.currentUser;
    if (user != null && commentContent.trim().isNotEmpty) {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': commentContent.trim(),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear(); // Clear input field after adding the comment
    }
  }

  // Fetch user details for the comment
  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF1F3),
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading comments.'));
                }

                final comments = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final userId = comment['userId'] as String;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserDetails(userId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(title: Text('Loading...'));
                        }
                        if (userSnapshot.hasError ||
                            userSnapshot.data == null) {
                          return ListTile(title: Text('Unknown User'));
                        }

                        final userData = userSnapshot.data!;

                        return ListTile(
                          leading:  CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(
                                userData['profileImageUrl'] ?? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcbYYoQtVusBGIbEgOo3dyyL2k2AAFqSu6lDm0XJEQ-5kX3mTKqO5oRZoNoyPMr9-Ht2I&usqp=CAU'
                            ),
                          )
                            ,
                          title: Text(userData['name'] ?? 'Anonymous'),
                          subtitle: Text(comment['content']),

                          trailing: Text(
                              getTimeAgo(comment['createdAt'])),
                        );
                      },
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
                      labelText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _addComment(_commentController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
