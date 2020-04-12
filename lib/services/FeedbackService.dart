import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:v0/Dashboard.dart';

class FeedbackService{
  //Feedback Service
  submitFeedback(String email, String message) async {
    print("\nAdding review from " + CurrentUser.userID);
    await Firestore.instance.collection('feedback').document(CurrentUser.userID).collection('review').add({
      'email': email,
      'name': CurrentUser.displayName,
      'userId': CurrentUser.userID,
      'earnedPoints': CurrentUser.earnedPoints,
      'message': message,
    });
  }
}