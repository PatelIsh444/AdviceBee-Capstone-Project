//Class defines basic data for a group.
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInformation {
  final List<dynamic> moderators;
  final String groupID;
  final String groupName;
  final String groupDescription;
  final Timestamp dateCreated;
  final String createdBy;
  final int numOfPosts;
  final bool privateGroup;
  List<dynamic> advisors = new List();
  List<dynamic> bannedUsers = [];
  List<dynamic> userRequestToJoin = [];
  String imageURL;

  GroupInformation(
      this.groupID,
      this.moderators,
      this.groupName,
      this.groupDescription,
      this.dateCreated,
      this.createdBy,
      this.imageURL,
      this.numOfPosts,
      this.privateGroup,
      this.advisors,
      this.bannedUsers,
      this.userRequestToJoin,
      );
}