import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:telex/screens/home/user_profile_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "/addMarketplaceAd"),
        child: const Text("Sell"),
      ),
      appBar: AppBar(title: const Text('Marketplace')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('marketplace').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products available'));
          }
          final products = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 100),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              return _buildProductCard(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, QueryDocumentSnapshot product) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: product['imageUrl'] ?? '',
                placeholder: (context, url) => _buildShimmerImage(),
                errorWidget: (context, url, error) => _errorImage(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Price: :${product['price']} PKR'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTextButton(context, 'Bid', () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => BidBottomSheet(postId: product.id),
                      );
                    }),
                    _buildTextButton(context, 'View Bids', () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => ViewBidsBottomSheet(postId: product.id),
                      );
                    }),
                    // Add delete icon if the current user is the creator
                    if (currentUser != null && product['postedById'] == currentUser.uid)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Confirm deletion
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Ad'),
                                content: const Text('Are you sure you want to delete this ad?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete == true) {
                            // Delete the product from Firestore
                            await _firestore.collection('marketplace').doc(product.id).delete();
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTextButton(BuildContext context, String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.black)),
    );
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 200,
        color: Colors.white,
      ),
    );
  }

  Widget _errorImage() {
    return Container(
      height: 200,
      color: Colors.grey,
      child: const Icon(Icons.error, color: Colors.red, size: 40),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              title: Container(
                width: 100,
                height: 20,
                color: Colors.white,
              ),
              subtitle: Container(
                width: 50,
                height: 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
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
    if (_bidController.text.isEmpty) return;
    double bidAmount = double.parse(_bidController.text);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _firestore.collection('marketplace').doc(widget.postId).update({
        'bids': FieldValue.arrayUnion([
          {
            'bidderId': user.uid,
            'amount': bidAmount,
            'createdAt': DateTime.now(),
          }
        ]),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Place your bid',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bidController,
            decoration: const InputDecoration(
              labelText: 'Enter Bid Amount In PKR',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _placeBid,
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }
}

class ViewBidsBottomSheet extends StatelessWidget {
  final String postId;
  const ViewBidsBottomSheet({required this.postId});

  Future<List<Map<String, dynamic>>> _fetchBids() async {
    DocumentSnapshot postSnapshot =
    await FirebaseFirestore.instance.collection('marketplace').doc(postId).get();

    List<dynamic> bids = postSnapshot['bids'] ?? [];
    List<Map<String, dynamic>> bidDetails = [];

    for (var bid in bids) {
      String bidderId = bid['bidderId'];
      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(bidderId).get();

      bidDetails.add({
        'bidderName': userSnapshot['name'],
        'bidderImage': userSnapshot['imageUrl'],
        'bidAmount': bid['amount'],
        'bidderId': bid['bidderId'],
      });
    }
    return bidDetails;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchBids(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No bids available'));
        }

        List<Map<String, dynamic>> bids = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bids',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
                          ? CircleAvatar(backgroundImage: NetworkImage(bid['bidderImage']))
                          : const CircleAvatar(child: Icon(Icons.person)),
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
