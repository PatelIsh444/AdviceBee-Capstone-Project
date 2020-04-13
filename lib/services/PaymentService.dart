import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:v0/Dashboard.dart';

class PaymentService{
  //This will be a dynamic modifiable variable
  int purchaseIncreaseAmount = 50;
  Map<String, dynamic> payQuestionsLimitMap = {'Queen Bee':15, 'Worker Bee':5, 'Larvae':3};

  //Payment History and Add Credit card
  addUserCard(Token payMethod) async {
    String lastFour = payMethod.card.last4;
    String cardType = payMethod.card.brand;
    print("\nAdding card to " + CurrentUser.userID);
    String userRank = "Larvae";
    await Firestore.instance.collection("configuration").document("config").get().then((DocumentSnapshot snapshot){
      print("\nPurchase Questions:\n");
      print(snapshot.data["awardedNumberOfQuestionsAfterPurchase"]);
      payQuestionsLimitMap = snapshot.data["awardedNumberOfQuestionsAfterPurchase"];
    });
    if(CurrentUser.earnedPoints < 500){
      userRank = "Larvae";
    }else if(CurrentUser.earnedPoints < 1000){
      userRank = "Worker Bee";
    }else{
      userRank = "Queen Bee";
    }
    String itemName = "AdviceBee " + payQuestionsLimitMap[userRank].toString() + " more questions";
    await Firestore.instance.collection('cards').document(CurrentUser.userID).collection('purchaseHistory').add({
      'itemPurchased': itemName,
      'date': DateTime.now(),
      'itemCost': '0.99',
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
    await Firestore.instance.collection('users').document(CurrentUser.userID).setData({
      'dailyQuestions': FieldValue.increment(payQuestionsLimitMap[userRank]),
    });
    print("\nDaily questions increased for " + CurrentUser.userID);
  }
}