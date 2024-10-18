import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telex/common/custom_form_button.dart';
import 'package:telex/common/custom_input_field.dart';
import 'package:telex/screens/auth/sign_in_screen.dart';
import 'package:telex/common/page_header.dart';
import 'package:telex/common/page_heading.dart';
import 'package:telex/common/responsive_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  File? _profileImage;
  final _signupFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numlId = TextEditingController();
  bool _isLoading = false;

  Future _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => _profileImage = imageTemporary);
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: ResponsiveWidget(
          maxWidth: 600.0,
          child: SingleChildScrollView(
            child: Form(
              key: _signupFormKey,
              child: Column(
                children: [
                  const PageHeader(height: 0.2),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const PageHeading(
                          title: 'Sign-up',
                        ),
                        profileImageWidget(),
                        const SizedBox(
                          height: 16,
                        ),
                        CustomInputField(
                          controller: _nameController,
                          labelText: 'Name',
                          hintText: 'Your name',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Name is required!';
                            } else if (textValue.length < 3) {
                              return 'Name must be at least 3 characters long!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        CustomInputField(
                          controller: _numlId,
                          labelText: 'Numl Id',
                          hintText: 'Numl Id',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Numl Id is required!';
                            } else if (textValue.length < 3) {
                              return 'Numl id must be at least 3 characters long!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        CustomInputField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Your email id',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Email is required!';
                            } else if (!emailRegExp.hasMatch(textValue)) {
                              return 'Please enter a valid email!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        CustomInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Your password',
                          isDense: true,
                          obscureText: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Password is required!';
                            } else if (textValue.length < 6) {
                              return 'Password must be at least 6 characters long!';
                            }
                            return null;
                          },
                          suffixIcon: true,
                        ),
                        const SizedBox(
                          height: 22,
                        ),
                        _isLoading
                            ? CircularProgressIndicator()
                            : CustomFormButton(
                                innerText: 'Signup',
                                onPressed: _handleSignupUser,
                              ),
                        const SizedBox(
                          height: 18,
                        ),
                        SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account ? ',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff939393),
                                    fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () => {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SignInScreen()))
                                },
                                child: const Text(
                                  'Log-in',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xff748288),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SizedBox profileImageWidget() {
    return SizedBox(
                        width: 100,
                        height: 100,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_sharp,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
  }

  void _handleSignupUser() async {
    // signup user
    if (_signupFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        //1 create user in auth
        // Sign up user with Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Define the image URL variable
        String imageUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7csvPWMdfAHEAnhIRTdJKCK5SPK4cHfskow&s';
        //2 media upload in firebase storage
        // Check if image is not null and upload to Firebase Storage
        if (_profileImage != null) {
          // Create a reference to Firebase Storage
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('userImages')
              .child('${userCredential.user!.uid}.jpg');

          // Upload the image file
          await storageRef.putFile(_profileImage!);

          // Get the image download URL
          imageUrl = await storageRef.getDownloadURL();
        }

        // saving user info in firestore
        // Save user info in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'imageUrl': imageUrl,
          'approved': false,
          'numl_id': _numlId.text.trim(),
        });

        // After signup, navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        // Handle errors here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error occurred')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
