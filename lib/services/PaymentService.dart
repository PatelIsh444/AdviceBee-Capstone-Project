import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:v0/Dashboard.dart';

class PaymentService{
  //This will be a dynamic modifiable variable
  int purchaseIncreaseAmount = 50;
  Map<String, dynamic> payQuestionsLimitMap = {'Larvae':3, 'Queen Bee':3, 'Worker Bee':3};

  //Pull Dynamic Config from Firestore
  generateConfigurationDetails() async {
    await Firestore.instance.collection("configuration").document("payConfig").get().then((DocumentSnapshot snapshot){
      payQuestionsLimitMap = snapshot.data["dailyQuestionsLimit"];
    });
  }

  //Payment History and Add Credit card
  addUserCard(Token payMethod) async {
    String lastFour = payMethod.card.last4;
    String cardType = payMethod.card.brand;
    print("\nAdding card to " + CurrentUser.userID);
    await Firestore.instance.collection('cards').document(CurrentUser.userID).collection('purchaseHistory').add({
      'itemPurchased': 'AdviceBee More Questions',
      'itemCost': '7.99',
      'lastFour': lastFour,
      'cardType': cardType,
    });
    await Firestore.instance.collection('cards').document(CurrentUser.userID).collection('tokens').document(payMethod.card.token).updateData({
      'cardToken': payMethod.card.token,
      'lastFour': lastFour,
      'cardType': cardType,
    });
    print("\nAdded card to " + CurrentUser.userID);
    print("\nAdded purchase history to " + CurrentUser.userID);
    chargeUser();
  }

  chargeUser(){
    print("\nCharged todo");
    //Then user is given question amount
    increaseQuestions();
  }

  increaseQuestions() async {
    print("\nIncreased daily questions for " + CurrentUser.userID);
    String userRank = "Larvae";
    if(CurrentUser.earnedPoints < 500){
      userRank = "Larvae";
    }else if(CurrentUser.earnedPoints < 1000){
      userRank = "Worker Bee";
    }else{
      userRank = "Queen Bee";
    }
    await Firestore.instance.collection('users').document(CurrentUser.userID).updateData({
      'earnedPoints': FieldValue.increment(payQuestionsLimitMap[userRank]),
    });
    print("\nDaily questions increased for " + CurrentUser.userID);
  }
}