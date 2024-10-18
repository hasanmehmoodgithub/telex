import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telex/screens/auth/sign_in_screen.dart';
import 'package:telex/common/responsive_widget.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final CollectionReference eventCollection =
  FirebaseFirestore.instance.collection('events');

  Stream<List<Event>> getEvents() {
    return eventCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromDocument(doc);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body:ResponsiveWidget(
        maxWidth: 600.0,
        child: StreamBuilder<List<Event>>(
          // get data from this stream
          stream: getEvents(),
          builder: (context, snapshot) {
            //loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            //empty case
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No events found'));
            }

            final events = snapshot.data!;

            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // If the event has an image, show it prominently
                        if (event.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              event.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                        SizedBox(height: 10),

                        // Display the event title
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        // Display the event description
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),

                        SizedBox(height: 12),

                        // Action buttons like Like, Comment, Share (optional)

                      ],
                    ),
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
class Event {
  final String title;
  final String description;
  final String? imageUrl;

  Event({
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory Event.fromDocument(DocumentSnapshot doc) {
    return Event(
      title: doc['title'],
      description: doc['des'],
      imageUrl: doc['img'],
    );
  }
}