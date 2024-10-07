import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _addAd() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle unauthenticated user (optional, based on your app's logic)
      return;
    }

    String? imageUrl;

    // Check if there's an image to upload
    if (_imageFile != null) {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('marketplace_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

    Navigator.pop(context); // Close the screen after posting
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Marketplace Ad')),
      body:ResponsiveWidget(
        maxWidth: 600.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
              SizedBox(height: 10),
              _imageFile != null ? Image.file(_imageFile!) : Container(),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _addAd, child: Text('Post Ad')),
            ],
          ),
        ),
      ),
    );
  }
}
