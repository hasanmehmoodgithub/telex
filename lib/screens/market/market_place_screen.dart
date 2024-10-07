import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telex/common/responsive_widget.dart';
import 'package:telex/screens/home/user_profile_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/addMarketplaceAd");
        },
        child: Text("Sell"),
      ),
      appBar: AppBar(title: Text('Marketplace')),
      body: ResponsiveWidget(
        maxWidth: 600.0,
        child: StreamBuilder(
          stream: _firestore.collection('marketplace').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No products available'));
            }
            final products = snapshot.data!.docs;

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // Rounded corners
                          child: CachedNetworkImage(
                            width: double.maxFinite,
                            imageUrl: product['imageUrl'] ?? '',
                            placeholder: (context, url) => Container(
                              width: double.maxFinite,
                              height: double.maxFinite,
                              color: Colors.grey,
                              // Grey container placeholder
                              child: Center(
                                child:
                                    CircularProgressIndicator(), // Optional loading indicator
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: double.maxFinite,
                              height: double.maxFinite,
                              color: Colors.grey,
                              // Grey background on error
                              child: Icon(
                                Icons.error, // Error icon in the center
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Price: \$${product['price']}'),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Open Bid Bottom Sheet
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) =>
                                          BidBottomSheet(postId: product.id),
                                    );
                                  },
                                  child: Text('Bid',style: TextStyle(color: Colors.black),),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Show the bottom sheet
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => ViewBidsBottomSheet(
                                          postId: product.id),
                                    );
                                  },
                                  child: Text('View Bids',style: TextStyle(color: Colors.black),),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BidBottomSheet extends StatefulWidget {
  final String postId;

  const BidBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  _BidBottomSheetState createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  final _bidController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _placeBid() async {
    double bidAmount = double.parse(_bidController.text);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle unauthenticated user (optional)
      return;
    }

    // Fetch user details (assuming you store them in a Firestore 'users' collection)
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Save the bid with user details in Firestore
    await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(widget.postId)
        .update({
      'bids': FieldValue.arrayUnion([
        {
          'bidderId': user.uid, // User ID
          'amount': bidAmount, // Bid Amount
          'createdAt': DateTime.now(),
        }
      ]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Makes the bottom sheet fit its content
        children: [
          Text(
            'Place your bid',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _bidController,
            decoration: InputDecoration(
              labelText: 'Bid Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _placeBid,
            child: Text('Submit Bid'),
          ),
        ],
      ),
    );
  }
}

class ViewBidsBottomSheet extends StatelessWidget {
  final String postId;

  ViewBidsBottomSheet({required this.postId});

  Future<List<Map<String, dynamic>>> _fetchBids() async {
    // Get the marketplace post document
    DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
        .collection('marketplace')
        .doc(postId)
        .get();

    List<dynamic> bids = postSnapshot['bids'];

    // Fetch user details for each bid
    List<Map<String, dynamic>> bidDetails = [];

    for (var bid in bids) {
      String bidderId = bid['bidderId'];
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(bidderId)
          .get();

      // Collect bid and user info
      bidDetails.add({
        'bidderName': userSnapshot['name'],
        'bidderImage': userSnapshot['imageUrl'],
        'bidAmount': bid['amount'],
        'bidderId': bid['bidderId'],
        'createdAt': bid['createdAt'],
      });
    }

    return bidDetails;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchBids(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No bids available'));
        }

        List<Map<String, dynamic>> bids = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bids',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: bids.length,
                itemBuilder: (context, index) {
                  var bid = bids[index];

                  return InkWell(
                    onTap: (){


                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            profileUserId: bid['bidderId'],
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: bid['bidderImage'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(bid['bidderImage']),
                            )
                          : CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(bid['bidderName']),
                      subtitle: Text('Bid: \$${bid['bidAmount']}'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
