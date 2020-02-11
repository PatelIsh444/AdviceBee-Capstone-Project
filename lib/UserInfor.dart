import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfomation {
  final String id;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final isNotGuest;

  UserInfomation({
    this.id,
    this.email,
    this.photoUrl,
    this.displayName,
    this.bio,
    this.isNotGuest,
  });

  factory UserInfomation.fromDocument(DocumentSnapshot doc) {
    return UserInfomation(
      id: doc['id'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      isNotGuest: true,
    );
  }
}

class LeaderboardInformation extends UserInfomation {
  final String id;
  final String photoUrl;
  final String displayName;
  final List<dynamic> topics;
  final int totalPoints;
  final String rank;
  bool isSelected;


  LeaderboardInformation(
    this.id,
    this.photoUrl,
    this.displayName,
    this.topics,
    this.totalPoints,
    this.rank,
      this.isSelected,
  );

  void printUserInfo(List<LeaderboardInformation> userList){
    for (int i = 0; i<userList.length; i++){
      print("-----------------------------------");
      print("Name = ${userList[i].displayName}");
      print("Topics = ${userList[i].topics}");
      print("totalPoints = ${userList[i].totalPoints}");
      print("Rank = ${userList[i].rank}");
    }
  }

}
