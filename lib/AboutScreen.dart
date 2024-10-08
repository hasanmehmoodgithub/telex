import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About TeleX'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About TeleX',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'TeleX is a group-based social media app designed to let you connect with others through group chats, events, and more. '
                  'You can create groups for NUML University, public, and private communities, chat with members, and engage in a variety of activities.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildFeatureItem('• Create groups for NUML University, public, and private communities.'),
            _buildFeatureItem('• Chat with group members easily.'),
            _buildFeatureItem('• Explore the marketplace and buy or sell items.'),
            _buildFeatureItem('• Enjoy offline games with friends.'),
            _buildFeatureItem('• Stay updated with event notifications.'),
            _buildFeatureItem('• Only NUML students can create an account, verified by admin approval.'),
            SizedBox(height: 16),
            Text(
              'Verification Process',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Only students from NUML University are allowed to create accounts. After registering, your account will be verified by an admin before you can access all features.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        feature,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
