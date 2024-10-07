import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telex/screens/chat/chat_screen.dart';
import 'package:telex/screens/home/user_profile_screen.dart';
import 'package:telex/utils/app_funtions.dart';

class ChatListScreen extends StatelessWidget {


  ChatListScreen();

  Stream<List<String>> getChatList() {

    return FirebaseFirestore.instance
        .collection('users')
        .doc( FirebaseAuth.instance.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: StreamBuilder<List<String>>(
        stream: getChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No active chats'));
          }

          final chatIds = snapshot.data!;
          return ListView.builder(
            itemCount: chatIds.length,
            itemBuilder: (context, index) {
              final chatId = chatIds[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid) // Assuming you are getting the chat list for the current user
                    .collection('chats')
                    .doc(chatId) // Accessing the chat document for the profile user
                    .get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('No chat found.')); // Handle the case where the document does not exist
                  }

                  final chatData = snapshot.data!.data() as Map<String, dynamic>;
                  final otherUserId = chatData['otherUserId'];
                  final lastMessage = chatData['lastMessage'];
                  final lastMessageTime = chatData['lastMessageTime'];

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: getUserData(otherUserId), // Fetch user data
                    builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (userSnapshot.hasError) {
                        return Center(child: Text('Error: ${userSnapshot.error}'));
                      }
                      if (!userSnapshot.hasData || userSnapshot.data == null) {
                        return Center(child: Text('User not found.'));
                      }

                      final userData = userSnapshot.data!;
                      final userName = userData['name'];
                      final userImageUrl = userData['imageUrl'];

                      return InkWell(
                        onTap: (){
                          openChat(context,userName,otherUserId);
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => UserProfileScreen(
                          //       profileUserId: otherUserId,
                          //     ),
                          //   ),
                          // );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(userImageUrl), // User avatar
                          ),
                          title: Text(userName), // User name
                          subtitle: Text(lastMessage ?? 'No messages yet.'),
                          trailing: Text(   getTimeAgo(lastMessageTime), style: TextStyle(fontSize: 12,color: Colors.grey)),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  void openChat(BuildContext context, String profileUserName, String profileUserId) {
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
}
Future<Map<String, dynamic>?> getUserData(String userId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (snapshot.exists) {
    return snapshot.data() as Map<String, dynamic>;
  } else {
    return null; // Handle user not found case
  }
}

