import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String? _postImageUrl;
  bool _isAnonymous = false; // For anonymous posts

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Post"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Post Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Post Image
              _postImageUrl != null
                  ? Image.network(_postImageUrl!, height: 100) // Display selected image
                  : Container(),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("Pick Post Image (optional)"),
              ),
              SizedBox(height: 16),

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
                  Text("Post Anonymously"),
                ],
              ),

              // Create Post Button
              ElevatedButton(
                onPressed: _createPost,
                child: Text("Create Post"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload to Firebase Storage and get URL
      final url = await _uploadImageToFirebase(pickedFile.path);
      setState(() {
        _postImageUrl = url;
      });
    }
  }

  Future<String?> _uploadImageToFirebase(String filePath) async {
    try {
      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Create a reference to the storage location
      Reference ref = FirebaseStorage.instance.ref().child('post_images/$fileName');

      // Upload the file
      await ref.putFile(File(filePath));

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _createPost() async {
    if (_formKey.currentState!.validate()) {
      // Create a new post in Firestore
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('posts').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': _postImageUrl,
        'isAnonymous': _isAnonymous,
        'createdDate': Timestamp.now(),
        'createdBy': _isAnonymous ? 'Anonymous' : 'User ID here', // Replace with actual user ID
        'likes': [],
        'likeCount':0,// Initialize with an empty list for user IDs who liked the post
        'comments': [], // Initialize with an empty list for comments
      });

      // Clear the text fields
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _postImageUrl = null; // Clear the post URL
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Post created successfully!")));

      // Optionally navigate back to the previous screen
      Navigator.pop(context);

    }
  }
}
