import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telex/screens/chat/chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String profileUserId;

  UserProfileScreen({
    required this.profileUserId,
  });

  Future<Map<String, dynamic>> getUserProfile() async {

    final doc = await FirebaseFirestore.instance.collection('users').doc(profileUserId).get();
    return doc.data() as Map<String, dynamic>; // Ensure Firestore document has data
  }

  void openChat(BuildContext context, String profileUserName) {
    final combinedId = createCombinedId(FirebaseAuth.instance.currentUser!.uid, profileUserId);

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          combinedId: combinedId,
          currentUserId:  FirebaseAuth.instance.currentUser!.uid,
          profileUserId: profileUserId,
          profileUserName: profileUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          final userProfile = snapshot.data!;
          final userName = userProfile['name'];
          final userImage = userProfile['imageUrl'] ?? '';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userImage.isNotEmpty
                      ? NetworkImage(userImage)
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                SizedBox(height: 20),
                Text(userName, style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                profileUserId==FirebaseAuth.instance.currentUser!.uid? SizedBox():ElevatedButton(
                  onPressed: () => openChat(context, userName),
                  child: Text('Chat with $userName'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
String createCombinedId(String userId1, String userId2) {
  if (userId1.compareTo(userId2) < 0) {
    return '${userId1}_$userId2';
  } else {
    return '${userId2}_$userId1';
  }
}