
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

String getTimeAgo(Timestamp timestamp) {
  // Convert Firebase Timestamp to DateTime
  DateTime dateTime = timestamp.toDate();

  // Use timeago to format it as "time ago"
  return timeago.format(dateTime);
}