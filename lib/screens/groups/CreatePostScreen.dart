import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:telex/common/responsive_widget.dart';

class CreatePostScreen extends StatefulWidget {
  final String groupId; // Group ID to associate the post with

  CreatePostScreen({required this.groupId});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _localImageFile; // To hold the locally selected image file
  String? _postImageUrl;
  bool _isAnonymous = false; // For anonymous posts

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
      ),
      body: ResponsiveWidget(
        maxWidth: 600.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Post Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Post Image
                _localImageFile != null
                    ? Image.file(_localImageFile!, height: 100) // Display locally selected image
                    : Container(),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Pick Post Image (optional)"),
                ),
                const SizedBox(height: 16),

                // Anonymous Post Toggle
                Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value!;
                        });
                      },
                    ),
                    const Text("Post Anonymously"),
                  ],
                ),

                // Create Post Button
                ElevatedButton(
                  onPressed: _createPost,
                  child: const Text("Create Post"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localImageFile = File(pickedFile.path); // Display the image locally before uploading
      });
    }
  }

  Future<void> _uploadImageToFirebase(String filePath) async {
    try {
      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Create a reference to the storage location
      Reference ref = FirebaseStorage.instance.ref().child('post_images/$fileName');

      // Upload the file
      await ref.putFile(File(filePath));

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();
      setState(() {
        _postImageUrl = downloadUrl; // Set the URL after upload
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _createPost() async {
    if (_formKey.currentState!.validate()) {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // If an image is selected, upload it first
      if (_localImageFile != null) {
        await _uploadImageToFirebase(_localImageFile!.path);
      }

      // Create a new post in Firestore
      String postId = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('posts')
          .doc(postId)
          .set({
        'postId': postId, // Add postId field
        'groupId': widget.groupId, // Add groupId field
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': _postImageUrl, // Add the uploaded image URL
        'isAnonymous': _isAnonymous,
        'createdDate': Timestamp.now(),
        'createdBy':FirebaseAuth.instance.currentUser!.uid, // Replace with actual user ID
        'likes': [],
        'likeCount': 0, // Initialize with 0 for like count
        'comments': [], // Initialize with an empty list for comments
      });

      // Close the loading dialog
      Navigator.pop(context);

      // Clear the text fields
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _localImageFile = null; // Clear the local image file
        _postImageUrl = null; // Clear the post image URL
      });

      // Show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Post created successfully!")));

      // Optionally navigate back to the previous screen
      Navigator.pop(context);
    }
  }
}
