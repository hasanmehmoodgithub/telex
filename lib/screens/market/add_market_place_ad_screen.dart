import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';  // Add shimmer package for loading effect


import 'package:telex/common/responsive_widget.dart';

class AddMarketplaceAdScreen extends StatefulWidget {
  const AddMarketplaceAdScreen({Key? key}) : super(key: key);

  @override
  _AddMarketplaceAdScreenState createState() => _AddMarketplaceAdScreenState();
}

class _AddMarketplaceAdScreenState extends State<AddMarketplaceAdScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;  // Loading state for posting ad

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _addAd() async {
    setState(() {
      _isLoading = true;  // Set loading state to true
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle unauthenticated user (optional, based on your app's logic)
      return;
    }

    String? imageUrl;

    // Check if there's an image to upload
    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance.ref().child(
          'marketplace_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      imageUrl = await storageRef.getDownloadURL();
    }

    // Add post to Firestore
    await FirebaseFirestore.instance.collection('marketplace').add({
      'title': _titleController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0, // Ensure price is valid
      'imageUrl': imageUrl, // This will be null if no image is provided
      'createdAt': FieldValue.serverTimestamp(),
      'postedBy': user.displayName ?? user.email, // Add 'postedBy' field with user's name or email
      'postedById': user.uid, // Store user ID as well
      'bids': [],
      'comments': [],
    });

    setState(() {
      _isLoading = false;  // Set loading state to false
    });

    Navigator.pop(context); // Close the screen after posting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Marketplace Ad'),

      ),
      body: Stack(
        children: [
          ResponsiveWidget(
            maxWidth: 600.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',

                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',

                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(),
                      ),
                      child: _imageFile != null
                          ? Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      )
                          : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _addAd,
                    style: ElevatedButton.styleFrom(

                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Post Ad',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            ),
        ],
      ),
    );
  }
}
