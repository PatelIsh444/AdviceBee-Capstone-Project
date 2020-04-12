import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v0/Dashboard.dart';

class FeedbackService{
  Future<void> submitFeedback(String message) async {
    await Firestore.instance.collection('feedback').document(CurrentUser.userID).setData({
      'userId': CurrentUser.userID,
    });

    Firestore.instance.collection('feedback').document(CurrentUser.userID).collection('review').add({
      'email': CurrentUser.email,
      'name': CurrentUser.displayName,
      'userId': CurrentUser.userID,
      'earnedPoints': CurrentUser.earnedPoints,
      'message': message,
      'dateRated': Timestamp.now()
    });
  }
}
