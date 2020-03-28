import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:v0/Dashboard.dart';

class PaymentService{
  //This will be a dynamic modifiable variable
  int purchaseIncreaseAmount = 50;

  addUserCard(PaymentMethod payMethod) async {
    String lastFour = payMethod.card.last4;
    String cardType = payMethod.card.brand;
    print("\nAdding card to " + CurrentUser.userID);
    await Firestore.instance.collection('cards').document(CurrentUser.userID).collection('tokens').add({
      'cardToken': payMethod.card.token,
      'lastFour': lastFour,
      'cardType': cardType,
    });
    print("\nAdded card to " + CurrentUser.userID);
    chargeUser();
  }

  chargeUser(){
    print("\nCharged todo");
    //Then user is given question amount
    increaseQuestions();
  }

  increaseQuestions() async {
    print("\nIncreased daily questions for " + CurrentUser.userID);
    await Firestore.instance.collection('users').document(CurrentUser.userID).updateData({
      'earnedPoints': FieldValue.increment(purchaseIncreaseAmount),
    });
    print("\nDaily questions increased for " + CurrentUser.userID);
  }
}