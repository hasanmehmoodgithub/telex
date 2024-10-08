import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telex/common/responsive_widget.dart';

import '../../common/page_header.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from FireStore
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        userName = userData['name'] ?? 'Guest'; // Fetch user name
        profileImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150'; // Fetch user profile image URL
      });
      bool approvedStatus = userData['approved'] ?? false; // Fetch user name
      if(!approvedStatus){
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ApprovalDialog();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF1F3),

      body: SingleChildScrollView(

        child: SafeArea(
          child: ResponsiveWidget(
            maxWidth: 600.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                              profileImageUrl ?? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcbYYoQtVusBGIbEgOo3dyyL2k2AAFqSu6lDm0XJEQ-5kX3mTKqO5oRZoNoyPMr9-Ht2I&usqp=CAU'
                          ),
                        ),
                        // Profile Image
                        const SizedBox(width: 16),
                        // User Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut(); // Sign out the user
                            Navigator.pushReplacementNamed(context, '/sigIn'); // Redirect to signin screen
                          },
                        ),
                      ],
                    ),
                  ),
                  // Profile Image and Name
                  const PageHeader(height: 0.3,),

                  const SizedBox(height: 24),
                  // Cards Section
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildCard(
                        context,
                        'Groups',
                        Icons.group,
                        const Color(0xff36788B),
                            () {
                          Navigator.pushNamed(context, '/groups');
                        },
                      ),
                      _buildCard(
                        context,
                        'Marketplace',
                        Icons.store,
                        const Color(0xffFE9F39),
                            () {
                          Navigator.pushNamed(context, '/marketplace');
                        },
                      ),
                      _buildCard(
                        context,
                        'Events',
                        Icons.event,
                        const Color(0xffF24E46),
                            () {
                          Navigator.pushNamed(context, '/events');
                        },
                      ),
                      _buildCard(
                        context,
                        'Chats',
                        Icons.chat,
                        const Color(0xff699E89),
                            () {
                          Navigator.pushNamed(context, '/chatsList');
                        },
                      ),
                      _buildCard(
                        context,
                        'Games',
                        Icons.games,
                         Colors.blueAccent,
                            () {
                          Navigator.pushNamed(context, '/games');
                        },
                      ),
                      _buildCard(
                        context,
                        'About',
                        Icons.app_blocking_outlined,
                        Colors.deepPurple,
                            () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ApprovalDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevents back navigation
      child: Scaffold(
        backgroundColor: Colors.black54, // 0.5 opacity
        body: Center(
          child: AlertDialog(
            backgroundColor: Colors.white,
            content: Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Please wait for admin approval or verification to proceed. For further inquiries, contact us at telex_support@gmail.com.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            actions: <Widget>[
            ],
          ),
        ),
      ),
    );
  }
}

