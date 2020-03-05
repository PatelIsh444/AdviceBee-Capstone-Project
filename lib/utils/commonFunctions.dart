/*Miscellaneous functions that are common among pages*/
import 'GroupInformation.dart';
import '../MoreMenu.dart';
import '../SearchBar.dart';
import '../User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flushbar/flushbar.dart';
import 'dart:async';
import '../services/AuthProvider.dart';
import 'package:flutter/material.dart';
import '../landing.dart';
import '../Dashboard.dart';
import '../GroupPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

List<SearchList> getSearchBarData()  {
  List<SearchList> databaseSearchQuery=new List();

  //Get user information
  Firestore.instance
      .collection('users')
      .orderBy('displayName', descending: false)
      .getDocuments()
      .then((QuerySnapshot data) =>
      data.documents.forEach((doc) => databaseSearchQuery.add(new SearchList(
        doc["displayName"],
        "user",
        doc.documentID,
        null,
        null,
      ))));

  //Get Group information
  Firestore.instance
      .collection('groups')
      .orderBy('groupName', descending: false)
      .getDocuments()
      .then((QuerySnapshot data) =>
      data.documents.forEach((doc) => databaseSearchQuery.add(new SearchList(
        doc["groupName"],
        "group",
        doc.documentID,
        null,
        new GroupInformation(
          doc.documentID,
          doc["moderators"],
          doc["groupName"],
          doc["groupDescription"],
          doc["dateCreated"],
          doc["createdBy"],
          doc["groupImage"],
          doc["numOfPosts"],
          doc["privateGroup"],
          doc["advisors"],
          doc["bannedUsers"],
          doc["userRequestToJoin"],
        ),
      ))));

  Firestore.instance
      .collectionGroup('topicQuestions')
      .orderBy('dateCreated', descending: true)
      .getDocuments()
      .then((QuerySnapshot data) =>
      data.documents.forEach((doc)=> databaseSearchQuery.add(new SearchList(
        doc["question"],
        "dashboard",
        doc["topicName"],
        doc.documentID,
        null,
      ))));

  return databaseSearchQuery;
}

//Function for getting user's information
Future<User> getUserInformation(String passedUserID) async {
  User userInfo;

  await Firestore.instance
      .collection('users')
      .document(passedUserID)
      .get()
      .then((DocumentSnapshot doc) {
    userInfo = User.fromDocument(doc);
  });
  return userInfo;
}

//Check if a user is marked as anonymous in Firebase
Future<bool> isAnonymousUser() async{
  FirebaseUser user = await FirebaseAuth.instance.currentUser();
  return user.isAnonymous;
}

//Function will check a user's daily points. Will reset every 24 hours.
Future<void> checkDailyPoints() async {
  await FirebaseAuth.instance.currentUser().then((curUser) {
    if(!curUser.isAnonymous)
    {
      DocumentReference curUserDocRef = Firestore.instance.collection('users').document(curUser.uid);

      curUserDocRef.get().then((DocumentSnapshot doc) {
        Timestamp lastPointReset = doc["lastPointReset"];
        int lastPointResetEpoch = lastPointReset.millisecondsSinceEpoch;
        int currentTime = Timestamp.now().millisecondsSinceEpoch;
        int dailyPoints = doc["dailyPoints"];

        if (((currentTime - lastPointResetEpoch) >= 86400000) &&
            (dailyPoints < 100)) {
          curUserDocRef.updateData({
            'lastPointReset': Timestamp.now(),
            'dailyPoints': 100,
          });
        }
      });
    }
  });
}

//Widget that prints pops up an alert with a failed to update message
Widget imageFailedToUpdateMessage(BuildContext context){
  return Flushbar(
    title: "Error!",
    message:
    'Unkown error occurred, please try again later.',
    duration: Duration(seconds: 3),
    backgroundColor: Colors.red,

  )..show(context);
}

//Alert message when user successfully uploads a picture
Widget imageUpdatedMessage(BuildContext context){
  return Flushbar(
    message:
    'Photo updated, looking good!',
    duration: Duration(seconds: 3),
    backgroundColor: Colors.teal,

  )..show(context);
}

//Flushbar display to prompt user to create an account
Widget guestUserSignInMessage(BuildContext context) {
  return Flushbar(
    title: "You are not logged in!",
    message:
    "Create an account to see what the buzz is about! "
        "Press sign up to create an account.",
    duration: Duration(seconds: 6),
    mainButton: FlatButton(
      color: Colors.white,
      textColor: Colors.teal,
      padding: EdgeInsets.only(left: 1, right: 1),
      onPressed: () {
        try {
          final auth = AuthProvider.of(context);
          auth.SignOut();
          //Destroy all navigation stacks
          Navigator.of(context).pushNamedAndRemoveUntil(MyApp.id, (Route<dynamic> route) => false);
        }catch (e) {
          print(e.toString());
        }
        CurrentUser = null;
      },
      child: Text(
          "Sign Up",
          style: TextStyle(fontSize: 20.0,) //decoration: TextDecoration.underline,),
      ),
    ),
    backgroundColor: Colors.teal,
  )..show(context);
}

Widget userCantLikeTheirPostMessage(BuildContext context) {
  return Flushbar(
    title: "This is your post!",
    message: "Sorry, you can't like your own post!",
    duration: Duration(seconds: 6),
    backgroundColor: Colors.teal,
  )..show(context);
}

Widget loadingScaffold(int currentTab, BuildContext context, GlobalKey key, bool isFirstPage, String heroName){
  return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        tooltip: 'Increment',
        heroTag: heroName,
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 18,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, isFirstPage),
      body: Center(child: CircularProgressIndicator()));
}