import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:telex/screens/auth/sign_up_page.dart';
import 'package:telex/screens/chat/chat_list_screen.dart';

import 'package:telex/screens/events/event_screen.dart';
import 'package:telex/screens/groups/Group_Feed_Screen.dart';
import 'package:telex/screens/market/add_market_place_ad_screen.dart';
import 'package:telex/screens/market/market_place_screen.dart';

import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:telex/screens/splash_screen.dart';
import 'package:telex/screens/auth/sign_in_screen.dart';

import 'package:telex/screens/home/home_screen.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/sigIn': (context) => SignInScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/groups': (context) => GroupFeedScreen(),
        '/marketplace': (context) => MarketplaceScreen(),
        '/addGroupPost': (context) => AddGroupPostScreen(groupId: ModalRoute.of(context)!.settings.arguments as String),
        '/addMarketplaceAd': (context) => AddMarketplaceAdScreen(),
        '/chatsList': (context) => ChatListScreen(),
        '/singleChat': (context) => SingleChatScreen(chatId: ModalRoute.of(context)!.settings.arguments as String),
        "/events": (context) =>EventScreen()
      },
    );
  }
}









//














class AddGroupPostScreen extends StatefulWidget {
  final String groupId;

  AddGroupPostScreen({super.key, required this.groupId});

  @override
  _AddGroupPostScreenState createState() => _AddGroupPostScreenState();
}

class _AddGroupPostScreenState extends State<AddGroupPostScreen> {
  final _postController = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addPost() async {
    final user = _auth.currentUser;

    if (user != null) {
      await _database.ref('groups/${widget.groupId}/posts').push().set({
        'userId': user.uid,
        'text': _postController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              decoration: InputDecoration(labelText: 'Enter your post'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _addPost, child: Text('Post')),
          ],
        ),
      ),
    );
  }
}



class SingleChatScreen extends StatefulWidget {
  final String chatId;

  SingleChatScreen({super.key, required this.chatId});

  @override
  _SingleChatScreenState createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;

    if (user != null) {
      await _database.ref('chats/${widget.chatId}/messages').push().set({
        'senderId': user.uid,
        'text': _messageController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _database.ref('chats/${widget.chatId}/messages').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final Map<dynamic, dynamic> messagesMap = snapshot.data!.snapshot.value as Map;
                  final List<dynamic> messages = messagesMap.values.toList();

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messages[index]['text']),
                        subtitle: Text('Sent by: ${messages[index]['senderId']}'),
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No messages'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Enter your message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
