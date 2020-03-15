import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

//basic information-holding class for user
class User {
  String displayName;
  String email;
  String userID;
  String profilePicURL;
  String bio;
  List<dynamic> myPosts;
  List<dynamic> blocked;
  List<dynamic> favoritePosts;
  List<dynamic> joinedGroups;
  List<dynamic> followers;
  List<dynamic> following;
  List<dynamic> likedPosts;
  List<dynamic> myTopics;
  List<dynamic> myResponses;
  int dailyPoints;
  int earnedPoints;
  bool isNotGuest=false;


  User();

  User.withInfo({
    this.displayName,
    this.email,
    this.userID,
    this.profilePicURL,
    this.myPosts,
    this.favoritePosts,
    this.joinedGroups,
    this.followers,
    this.following,
    this.likedPosts,
    this.myResponses,
    this.bio,
    this.blocked,
    this.dailyPoints,
    this.earnedPoints,
    this.isNotGuest,
    this.myTopics,
  });

  User.searchInfo(
    this.displayName,
    this.userID,
    this.profilePicURL,
  );

  User.withID(String passedUserID) {
    getUserInformation(passedUserID).then((DocumentSnapshot doc) {
      this.displayName = doc["displayName"];
      this.email = doc["email"];
      this.userID = doc.documentID;
      this.profilePicURL = doc["profilePicURL"];
      this.myPosts = doc["myPosts"];
      this.favoritePosts = doc["favoritePosts"];
      this.joinedGroups = doc["joinedGroups"];
      this.followers = doc["followers"];
      this.following = doc["following"];
      this.likedPosts = doc["likedPosts"];
      this.myResponses = doc["myResponses"];
      this.bio = doc["bio"];
      this.dailyPoints = doc["dailyPoints"];
      this.earnedPoints = doc["earnedPoints"];
      this.isNotGuest = true;
      this.blocked = doc["blocked"];
    });
  }
  factory User.fromDocument(DocumentSnapshot doc) {
    return User.withInfo(
      displayName: doc["displayName"],
      email: doc["email"],
      userID: doc.documentID,
      profilePicURL: doc["profilePicURL"],
      myPosts: doc["myPosts"],
      favoritePosts: doc["favoritePosts"],
      joinedGroups: doc["joinedGroups"],
      followers: doc["followers"],
      following: doc["following"],
      likedPosts: doc["likedPosts"],
      myResponses: doc["myResponses"],
      bio: doc["bio"],
      blocked: doc["blocked"],
      dailyPoints: doc["dailyPoints"],
      earnedPoints: doc["earnedPoints"],
      myTopics: doc["myTopics"],
      isNotGuest: true,
    );
  }


  Future<DocumentSnapshot> getUserInformation(String passedUserID) async {
    return await Firestore.instance
        .collection('users')
        .document(passedUserID)
        .get();
  }
}
