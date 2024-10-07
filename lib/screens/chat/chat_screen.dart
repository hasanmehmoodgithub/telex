import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatelessWidget {
  final String combinedId;
  final String currentUserId;
  final String profileUserId;
  final String profileUserName;

  ChatScreen({
    required this.combinedId,
    required this.currentUserId,
    required this.profileUserId,
    required this.profileUserName,
  });

  final TextEditingController _messageController = TextEditingController();

  void sendMessage(String content) async {
    if (content.isEmpty) return;

    // Create a new ChatMessage instance
    final message = ChatMessage(
      senderId: currentUserId,
      receiverId: profileUserId,
      content: content,
      timestamp: DateTime.now(),
    );

    // Get a reference to the messages collection
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(combinedId)
        .collection('messages')
        .doc(); // Automatically generate a message ID

    // Batch operation for sending the message and updating both users' chat lists
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Add the message to the messages collection
    batch.set(messageRef, message.toMap());

    // Update sender's chat list with the last message info
    final senderChatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(profileUserId); // The ID of the other person

    batch.set(senderChatRef, {
      'lastMessage': content,
      'lastMessageTime': DateTime.now(),
      'otherUserId': profileUserId,

    });

    // Update receiver's chat list with the last message info
    final receiverChatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(profileUserId)
        .collection('chats')
        .doc(currentUserId); // The ID of the sender (current user)

    batch.set(receiverChatRef, {
      'lastMessage': content,
      'lastMessageTime': DateTime.now(),
      'otherUserId': currentUserId,
    });

    // Commit the batch write
    await batch.commit();

    // Clear the message input
    _messageController.clear();
  }


  Stream<List<ChatMessage>> getMessages() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(combinedId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profileUserName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: getMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByCurrentUser = message.senderId == currentUserId;

                    return Align(
                      alignment: isSentByCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSentByCurrentUser ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message.content),
                      ),
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(_messageController.text);
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
class ChatMessage {
  final String senderId;
  final String receiverId;
  final String content; // Replace `message` with `content` here
  final DateTime timestamp;
  final String messageType; // Optional if you're supporting different message types
  final bool isRead;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.content, // Updated here
    required this.timestamp,
    this.messageType = 'text', // Default to 'text'
    this.isRead = false, // Default to unread
  });

  // Convert ChatMessage to a Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content, // Updated here
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'isRead': isRead,
    };
  }

  // Create a ChatMessage from a Firestore document
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'], // Updated here
      timestamp: DateTime.parse(map['timestamp']),
      messageType: map['messageType'] ?? 'text',
      isRead: map['isRead'] ?? false,
    );
  }
}

