import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:telex/common/responsive_widget.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  bool _isPrivate = false;
  String? _groupImageUrl;
  bool _isLoading = false; // To track loading state

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Group"),
        centerTitle: true,
      ),
      body: ResponsiveWidget(
        maxWidth: 600.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Group Name
                TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Group Description
                TextFormField(
                  controller: _groupDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Group Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Group Image
                if (_groupImageUrl != null)
                  Image.file(File(_groupImageUrl!), height: 100, fit: BoxFit.cover),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Pick Group Image (optional)"),
                ),
                const SizedBox(height: 16),

                // Private Group Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value!;
                        });
                      },
                    ),
                    Text("Private Group"),
                  ],
                ),

                // Create Group Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup, // Disable button when loading
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white) // Show loading indicator
                      : Text("Create Group"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
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
        _groupImageUrl = pickedFile.path; // Set local file path to display image
      });
    }
  }

  Future<String?> _uploadImageToFirebase(String filePath) async {
    try {
      // Show loading dialog
      setState(() {
        _isLoading = true;
      });

      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Create a reference to the storage location
      Reference ref = FirebaseStorage.instance.ref().child('group_images/$fileName');

      // Upload the file
      await ref.putFile(File(filePath));

      // Get the download URL
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    } finally {
      setState(() {
        _isLoading = false; // Hide loading dialog
      });
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      // Get the current user's ID
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? 'Anonymous'; // Fallback to 'Anonymous' if user not logged in

      // Use a default image URL if none was selected
      String defaultImageUrl = 'https://media.istockphoto.com/id/1223631367/vector/multicultural-group-of-people-is-standing-together-team-of-colleagues-students-happy-men-and.jpg?s=612x612&w=0&k=20&c=9Mwxpq9gADCuEyvFxUdmNhlQea5PED-jwCmqtfgdXhU=';
      String? groupImageUrl = _groupImageUrl != null ? await _uploadImageToFirebase(_groupImageUrl!) : defaultImageUrl;

      // Generate a unique group ID
      String groupId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a new group in Firestore
      await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
        'name': _groupNameController.text,
        'description': _groupDescriptionController.text,
        'isPrivate': _isPrivate,
        'createdDate': Timestamp.now(),
        'createdBy': userId, // Set the creator of the group
        'groupUrl': groupImageUrl, // Save the group image URL
        'members': [userId], // Add the creator as the first member
      });

      // Clear the text fields
      _groupNameController.clear();
      _groupDescriptionController.clear();
      setState(() {
        _groupImageUrl = null; // Clear the selected image URL
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Group created successfully!")));

      // Optionally navigate back to the previous screen
      Navigator.pop(context);
    }
  }
}
