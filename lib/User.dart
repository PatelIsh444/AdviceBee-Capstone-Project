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
  List<dynamic> favoritePosts;
  List<dynamic> joinedGroups;
  List<dynamic> followers;
  List<dynamic> following;
  List<dynamic> likedPosts;
  List<dynamic> myTopics;
  List<dynamic> myResponses;
  List<dynamic>blocked;
  int dailyPoints;
  int earnedPoints;
  bool isNotGuest=false;
  var lastAccess;


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
    this.dailyPoints,
    this.earnedPoints,
    this.isNotGuest,
    this.myTopics,
    this.blocked,
    this.lastAccess,
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
      this.blocked = doc["blocked"];
      this.likedPosts = doc["likedPosts"];
      this.myResponses = doc["myResponses"];
      this.bio = doc["bio"];
      this.dailyPoints = doc["dailyPoints"];
      this.earnedPoints = doc["earnedPoints"];
      this.isNotGuest = true;
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
      blocked: doc["blocked"]==null?[]:doc["blocked"],
      likedPosts: doc["likedPosts"],
      myResponses: doc["myResponses"],
      bio: doc["bio"],
      dailyPoints: doc["dailyPoints"],
      earnedPoints: doc["earnedPoints"],
      myTopics: doc["myTopics"],
      lastAccess: doc['last access'],
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
