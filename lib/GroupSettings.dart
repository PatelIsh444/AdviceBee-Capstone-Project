import 'GroupPage.dart';
import './utils/GroupInformation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'QuestionPage.dart';
import 'MoreMenu.dart';
import 'User.dart';
import './utils/commonFunctions.dart';
import 'newProfile.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class groupSettingsPage extends StatefulWidget {
  final GroupInformation groupInfo;
  List<questions> groupQuestions;

  groupSettingsPage(this.groupInfo, this.groupQuestions);

  @override
  _groupSettingsPageState createState() => _groupSettingsPageState();
}

class _groupSettingsPageState extends State<groupSettingsPage> {
  GlobalKey key = GlobalKey();
  List<User> memberInformation = [];
  Future<List<User>> memberInformationFuture;
  List<User> nonAdvisorList = new List();
  List<bool> isSelectedAdvisor = new List();
  List<User> newAdvisorList = new List();
  List<bool> isSelectedModerator = new List();
  List<User> nonModeratorList = new List();
  List<User> newModeratorList = new List();
  List<User> normalUserList = new List();
  List<bool> toBeBanned = new List();
  List<User> toBeBannedUsersList = new List();
  List<questions> groupQuestions;
  List<questions> selectedQuestions = new List();
  List<bool> isQuestionSelected = new List();
  File _image;
  GroupInformation groupInformation;

  List<User> bannedUserList = new List();
  List<User> unbanList = new List();
  List<bool> toBeUnbanned = new List();

  List<User> requestToJoinUsers = new List();

  @override
  void initState() {
    super.initState();
    memberInformationFuture = getGroupMemberInformation();
    groupInformation = widget.groupInfo;
    groupQuestions = widget.groupQuestions;
    groupQuestions.forEach((question) => isQuestionSelected.add(false));
  }

  Future<List<User>> getGroupMemberInformation() async {
    List<User> members = new List();

    await Firestore.instance
        .collection("users")
        .where('joinedGroups', arrayContains: widget.groupInfo.groupID)
        .orderBy("displayName")
        .getDocuments()
        .then((QuerySnapshot queryResult) {
      for (DocumentSnapshot doc in queryResult.documents) {
        members.add(User.fromDocument(doc));
      }
    });

    return members;
  }

  Future<GroupInformation> updateGroupInfo() async {
    GroupInformation newGroupInfo;
    await Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID)
        .get()
        .then((DocumentSnapshot doc) {
      newGroupInfo = new GroupInformation(
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
      );
    });
    return newGroupInfo;
  }

  Future<void> NotifyNewMembers(String newMemberID) async {
    final activityFeedRef = Firestore.instance.collection('Notification');
    final groupRef = Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID);

    //Join user to the group
    await Firestore.instance
        .collection('users')
        .document(newMemberID)
        .updateData({
      "joinedGroups": FieldValue.arrayUnion([groupInformation.groupID])
    });

    //Send notification to user telling them that they have been accepted.
    await activityFeedRef
        .document(newMemberID)
        .collection("NotificationItems")
        .document()
        .setData({
      "type": "groupAccept",
      "groupID": groupInformation.groupID,
      "profileImg": groupInformation.imageURL,
      "groupName": groupInformation.groupName,
      "timestamp": Timestamp.now(),
    });

    //Once notification is sent out, remove the request from the group.
    await groupRef.updateData({
      "userRequestToJoin": FieldValue.arrayRemove([newMemberID])
    });

    //Remove user from local list
    requestToJoinUsers
        .removeWhere((User userInfo) => userInfo.userID == newMemberID);

    setState(() {
      updateGroupInfo();
    });
  }

  Future<void> NotifyDeclinedMembers(String declinedMemberID) async {
    final activityFeedRef = Firestore.instance.collection('Notification');
    final groupRef = Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID);

    //Send notification to user showing that the moderators declined inviting them.
    await activityFeedRef
        .document(declinedMemberID)
        .collection("NotificationItems")
        .document()
        .setData({
      "type": "groupDecline",
      "groupID": groupInformation.groupID,
      "profileImg": groupInformation.imageURL,
      "groupName": groupInformation.groupName,
      "timestamp": Timestamp.now(),
    });

    //Once notification is sent out, remove the request from the group.
    await groupRef.updateData({
      "userRequestToJoin": FieldValue.arrayRemove([declinedMemberID])
    });

    //Remove user from local list
    requestToJoinUsers
        .removeWhere((User userInfo) => userInfo.userID == declinedMemberID);

    setState(() {
      updateGroupInfo();
    });
  }

  Future<void> NotifyNewAdvisors() async {
    final activityFeedRef = Firestore.instance.collection('Notification');
    final groupRef = Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID);

    //Local list so newAdvisorList can be deleted from
    List<User> localNewAdvisorList = List.from(newAdvisorList);

    // add a notification to the users's activity feed
    for (var advisor in localNewAdvisorList) {
      await activityFeedRef
          .document(advisor.userID)
          .collection("NotificationItems")
          .document()
          .setData({
        "type": "advisor",
        "groupID": groupInformation.groupID,
        "profileImg": groupInformation.imageURL,
        "groupName": groupInformation.groupName,
        "timestamp": Timestamp.now(),
      });

      await groupRef.updateData({
        'advisors': FieldValue.arrayUnion([advisor.userID]),
      });

      isSelectedAdvisor.removeAt(nonAdvisorList.indexOf(advisor));
      nonAdvisorList.remove(advisor);
    }
    setState(() {
      updateGroupInfo().then((newInfo) => groupInformation = newInfo);
    });
  }

  //Similar to NotifyNewAdvisors, but changes the type to moderators instead.
  Future<void> NotifyNewModerators() async {
    final activityFeedRef = Firestore.instance.collection('Notification');
    final groupRef = Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID);
    //Local list so we can delete from newModeratorList
    List<User> localNewModList = List.from(newModeratorList);

    // add a notification to the users's activity feed
    for (var moderator in localNewModList) {
      await activityFeedRef
          .document(moderator.userID)
          .collection("NotificationItems")
          .document()
          .setData({
        "type": "moderator",
        "groupID": groupInformation.groupID,
        "profileImg": groupInformation.imageURL,
        "groupName": groupInformation.groupName,
        "timestamp": Timestamp.now(),
      });
      //Add moderator to the list
      await groupRef.updateData({
        'moderators': FieldValue.arrayUnion([moderator.userID]),
      });
      isSelectedModerator.removeAt(nonModeratorList.indexOf(moderator));
      nonModeratorList.remove(moderator);
    }
    setState(() {
      updateGroupInfo().then((newInfo) {
        groupInformation = newInfo;
      });
    });
  }

  //Update information in database so that user is banned
  Future<void> banUser() async {
    for (var bannedUser in toBeBannedUsersList) {
      await Firestore.instance
          .collection('groups')
          .document(groupInformation.groupID)
          .updateData({
        'bannedUsers': FieldValue.arrayUnion([bannedUser.userID])
      });
      toBeBanned.removeAt(normalUserList.indexOf(bannedUser));
      normalUserList.remove(bannedUser);
    }
    setState(() {
      updateGroupInfo().then((newInfo) {
        groupInformation = newInfo;
      });
    });
  }

  //Reverse a users ban
  Future<void> unBanUser() async {
    for (var user in unbanList) {
      await Firestore.instance
          .collection('groups')
          .document(groupInformation.groupID)
          .updateData({
        'bannedUsers': FieldValue.arrayRemove([user.userID])
      });
      toBeUnbanned.removeAt(bannedUserList.indexOf(user));
      bannedUserList.remove(user);
    }
    setState(() {
      updateGroupInfo().then((newInfo) {
        groupInformation = newInfo;
      });
    });
  }

  Future<void> removePostFromDatabase() async {
    for (questions removedQuestion in selectedQuestions) {
      //Create document reference in order to delete from a user
      DocumentReference questionPath = Firestore.instance
          .collection("groups")
          .document(groupInformation.groupID)
          .collection("groupQuestions")
          .document(removedQuestion.postID);
      await Firestore.instance
          .collection('groups')
          .document(groupInformation.groupID)
          .collection("groupQuestions")
          .document(removedQuestion.postID)
          .delete();
      print(questionPath);
      await Firestore.instance
          .collection('users')
          .document(removedQuestion.createdBy)
          .updateData({
        'myPosts': FieldValue.arrayRemove([questionPath])
      });

      QuerySnapshot favoriteQuery = await Firestore.instance
          .collection('users').where("favoritePosts", arrayContains: questionPath)
          .getDocuments();

      for(DocumentSnapshot favorite in favoriteQuery.documents)
      {
        await Firestore.instance.collection('users')
            .document(favorite.documentID).updateData({
          'favoritePosts': FieldValue.arrayRemove([questionPath])
        }
        );
      }

      isQuestionSelected.removeAt(groupQuestions.indexOf(removedQuestion));
      groupQuestions.remove(removedQuestion);
    }
    setState(() {
      updateGroupInfo().then((newInfo) {
        groupInformation = newInfo;
      });
    });
  }

  Future getImageMenu() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Picture from..."),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                    GestureDetector(
                      child: Text("Camera"),
                      onTap: () {
                        getCameraImage();
                      },
                    ),
                    Padding(padding: EdgeInsets.all(7)),
                    GestureDetector(
                      child: Text("Gallery"),
                      onTap: () {
                        getGalleryImage();
                      },
                    ),
                  ])));
        });
  }

  /*Chooses an image from the camera then uploads it to firebase storage.
  * After image is successfully uploaded, it returns a message notifying them*/
  getCameraImage() async {
    //Select Image from camera
    Navigator.pop(context);
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: image.path,
      cropStyle: CropStyle.circle,
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
      //maxWidth: 160,
      //maxHeight: 160,
    );

    setState(() {
      _image = croppedImage ?? _image;
    });

    /*This code will be visited if the user actually selects a photo from
    their gallery or takes a picture with a camera. If they press the back
    button on their phone the image will be null and this code will not be
    visited*/
    if (croppedImage != null) {
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("groupPictures/" + groupInformation.groupID + "groupPicture");
      final StorageUploadTask uploadTask = pictureNameInStorage.putFile(_image);
      await uploadTask.onComplete;

      var imageURL = await pictureNameInStorage.getDownloadURL() as String;
      Firestore.instance
          .collection('groups')
          .document(groupInformation.groupID)
          .updateData({
        'groupImage': imageURL,
      });

      setState(() {
        groupInformation.imageURL = imageURL;
      });

      // return showDialog(context: context, builder: (BuildContext context) {
      if (uploadTask.isSuccessful) {
        imageUpdatedMessage(context);
      } else {
        imageFailedToUpdateMessage(context);
      }
      // });
    }
  }

  /*Chooses an image from the gallery then uploads it to firebase storage.
  * After image is successfully uploaded, it returns a message notifying them*/
  getGalleryImage() async {
    //Select Image from gallery
    Navigator.pop(context);
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: image.path,
      cropStyle: CropStyle.circle,
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
      //maxWidth: 160,
      //maxHeight: 160,
    );

    setState(() {
      _image = croppedImage ?? _image;
    });

    /*This code will be visited if the user actually selects a photo from
    their gallery or takes a picture with a camera. If they press the back
    button on their phone the image will be null and this code will not be
    visited*/
    if (croppedImage != null) {
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("groupPictures/" + groupInformation.groupID + "groupPicture");
      final StorageUploadTask uploadTask = pictureNameInStorage.putFile(_image);
      await uploadTask.onComplete;

      var imageURL = await pictureNameInStorage.getDownloadURL() as String;
      Firestore.instance
          .collection('groups')
          .document(groupInformation.groupID)
          .updateData({
        'groupImage': imageURL,
      });

      setState(() {
        groupInformation.imageURL = imageURL;
      });

      if (uploadTask.isSuccessful) {
        imageUpdatedMessage(context);
      } else {
        imageFailedToUpdateMessage(context);
      }
    }
  }

  streamUpdateGroupInfo(DocumentSnapshot doc) {
    if(doc.data != null)
    {
      groupInformation = new GroupInformation(
        doc.documentID != null ? doc.documentID : null,
        doc["moderators"] != null ? doc["moderators"] : null,
        doc["groupName"] != null ? doc["groupName"] : null,
        doc["groupDescription"] != null ? doc["groupDescription"] : null,
        doc["dateCreated"] != null ? doc["dateCreated"] : null,
        doc["createdBy"] != null ? doc["createdBy"] : null,
        doc["groupImage"] != null ? doc["groupImage"] : null,
        doc["numOfPosts"] != null ? doc["numOfPosts"] : null,
        doc["privateGroup"] != null ? doc["privateGroup"] : null,
        doc["advisors"] != null ? doc["advisors"] : null,
        doc["bannedUsers"] != null ? doc["bannedUsers"] : null,
        doc["userRequestToJoin"] != null ? doc["userRequestToJoin"] : null,
      );
    }
    else{
      groupInformation = null;
    }

  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return StreamBuilder(
      stream: Firestore.instance
          .collection("groups")
          .document(groupInformation.groupID)
          .snapshots(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasData) {
          streamUpdateGroupInfo(groupSnapshot.data);
          //If group information is null (such as deleting a container) return an empty container
          if(groupInformation == null)
            return Container();
          //Get a list of all users requesting to join the group, if applicable.
          if (groupInformation.privateGroup) {
            for (String userID in groupInformation.userRequestToJoin) {
              getUserInformation(userID).then((userInfo) {
                bool isInList = requestToJoinUsers
                    .any((User userInfo) => userInfo.userID == userID);
                setState(() {
                  if (!isInList) requestToJoinUsers.add(userInfo);
                });
              });
            }
          }
          return FutureBuilder(
              future: memberInformationFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  case ConnectionState.done:
                    if (snapshot.hasData) {
                      memberInformation = snapshot.data;
                      memberInformation.forEach((member) {
                        //Get advisors for group
                        if (groupInformation.advisors.length != 0) {
                          if (!groupInformation.advisors
                              .contains(member.userID)) {
                            if (!nonAdvisorList.contains(member)) {
                              nonAdvisorList.add(member);
                              isSelectedAdvisor.add(false);
                            }
                          }
                        }
                        //Do the same for moderators
                        if (!groupInformation.moderators
                            .contains(member.userID)) {
                          if (!nonModeratorList.contains(member)) {
                            nonModeratorList.add(member);
                            isSelectedModerator.add(false);
                          }
                        }
                        //Get a list of all non-moderator and not banned users
                        if (groupInformation.bannedUsers == null) {
                          if (!groupInformation.moderators
                              .contains(member.userID)) {
                            var user = normalUserList.firstWhere(
                                    (memberUser) =>
                                memberUser.userID == member.userID,
                                orElse: () => null);
                            if (user == null) {
                              normalUserList.add(member);
                              toBeBanned.add(false);
                            }
                          }
                        } else if (!groupInformation.moderators
                            .contains(member.userID) &&
                            !groupInformation.bannedUsers
                                .contains(member.userID)) {
                          var user = normalUserList.firstWhere(
                                  (memberUser) =>
                              memberUser.userID == member.userID,
                              orElse: () => null);
                          if (user == null) {
                            normalUserList.add(member);
                            toBeBanned.add(false);
                          }
                        }

                        //Get a list of all banned users
                        if (groupInformation.bannedUsers != null) {
                          if (groupInformation.bannedUsers
                              .contains(member.userID) &&
                              !bannedUserList.contains(member)) {
                            bannedUserList.add(member);
                            toBeUnbanned.add(false);
                          }
                        }
                      });
                    }
                    return Scaffold(
                      appBar: AppBar(
                        title: Text("${groupInformation.groupName} Settings"),
                      ),
                      bottomNavigationBar: globalNavigationBar(1, context, key, false),
                      body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            //Different cards containing settings for mods
                            newProfilePicture(deviceWidth),
                            addAdvisor(deviceWidth),
                            addModerator(deviceWidth),
                            banUsers(deviceWidth),
                            unbanUsers(deviceWidth),
                            removePosts(deviceWidth),
                            showUserRequestJoin(deviceWidth),
                            deleteGroupBox(deviceWidth),
                          ],
                        ),
                      ),
                    );
                }
                return null; //unreachable
              });
        }
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget showUserRequestJoin(double deviceWidth) {
    //If a group is private, show box allowing accept or decline
    if (groupInformation.privateGroup) {
      return Padding(
        padding: EdgeInsets.all(20.0),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(12.0),
          shadowColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(15.0),
            width: deviceWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
            ),
            constraints: BoxConstraints(minHeight: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  "Users Requesting to Join",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 2.0,
                ),
                SizedBox(
                  height: 10.0,
                ),
                ColumnBuilder(
                  itemCount: requestToJoinUsers.length,
                  itemBuilder: (context, index) {
                    return Card(
                      key: Key(requestToJoinUsers[index].userID),
                      elevation: 5,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => UserDetailsPage(
                                requestToJoinUsers[index].userID),
                          ));
                        },
                        child: Container(
                          child: Row(
                            children: <Widget>[
                              Container(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                  //Set the formatting for the name
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: <Widget>[
                                      RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: requestToJoinUsers[index]
                                                  .displayName,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                        EdgeInsets.fromLTRB(0, 5, 0, 2),
                                        child: Container(
                                          width: deviceWidth - 156,
                                          //Set the description for every card
                                          child: RichText(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                  requestToJoinUsers[index]
                                                      .bio,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      ButtonTheme.bar(
                                        child: ButtonBar(
                                          children: <Widget>[
                                            FlatButton(
                                              child: const Text('Accept'),
                                              onPressed: () {
                                                NotifyNewMembers(
                                                    requestToJoinUsers[index]
                                                        .userID);
                                              },
                                            ),
                                            FlatButton(
                                              child: const Text('Decline'),
                                              onPressed: () {
                                                NotifyDeclinedMembers(
                                                    requestToJoinUsers[index]
                                                        .userID);
                                              },
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else
      //Return a container if a group isn't private
      return Container();
  }

  //Widget to allow mods to ban users
  Widget banUsers(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Ban Users",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              ColumnBuilder(
                itemCount: normalUserList.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: Key(normalUserList[index].userID),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserDetailsPage(normalUserList[index].userID),
                        ));
                      },
                      child: Container(
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: toBeBanned[index],
                              onChanged: (bool value) {
                                setState(() {
                                  toBeBanned[index] = value;
                                  if (value) {
                                    toBeBannedUsersList
                                        .add(normalUserList[index]);
                                  } else {
                                    toBeBannedUsersList
                                        .remove(normalUserList[index]);
                                  }
                                });
                              },
                            ),
                            Container(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                //Set the formatting for the name
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: normalUserList[index]
                                                .displayName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
                                      child: Container(
                                        width: deviceWidth - 156,
                                        //Set the description for every card
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: normalUserList[index].bio,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    banUser();
                    setState(() {
                      updateGroupInfo().then((newInfo) {
                        groupInformation = newInfo;
                      });
                    });
                    Flushbar(
                      title: "User banned!",
                      message:
                      "The user has been banned! They can see posts, but no longer post or respond.",
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.teal,
                    )..show(context);
                  },
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child:
                  Text('Ban Users', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Widget to allow mods to ban users
  Widget unbanUsers(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Reinstate Users",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              ColumnBuilder(
                itemCount: bannedUserList.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: Key(bannedUserList[index].userID),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserDetailsPage(bannedUserList[index].userID),
                        ));
                      },
                      child: Container(
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: toBeUnbanned[index],
                              onChanged: (bool value) {
                                setState(() {
                                  toBeUnbanned[index] = value;
                                  if (value) {
                                    unbanList.add(bannedUserList[index]);
                                  } else {
                                    unbanList.remove(bannedUserList[index]);
                                  }
                                });
                              },
                            ),
                            Container(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                //Set the formatting for the name
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: bannedUserList[index]
                                                .displayName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
                                      child: Container(
                                        width: deviceWidth - 156,
                                        //Set the description for every card
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: bannedUserList[index].bio,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    unBanUser();
                    setState(() {
                      updateGroupInfo().then((newInfo) {
                        groupInformation = newInfo;
                      });
                    });
                    Flushbar(
                      title: "User unbanned!",
                      message:
                      "The user has been unbanned! They can now respond to posts and make responses again.",
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.teal,
                    )..show(context);
                  },
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child: Text('Reinstate Users',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Widget to change the profile picture of a group
  Widget buildProfileImage(String imageLink) {
    return Center(
      child: GestureDetector(
        onTap: getImageMenu,
        child: Container(
          width: 160.0,
          height: 160.0,
          decoration: BoxDecoration(
            image: new DecorationImage(
              image: new CachedNetworkImageProvider(imageLink),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(80.0),
            border: Border.all(
              color: Colors.white,
              width: 5.0,
            ),
          ),
        ),
      ),
    );
  }

  //Widget for replacing current profile picture
  Widget newProfilePicture(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Change Group Picture",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              buildProfileImage(groupInformation.imageURL),
              SizedBox(
                height: 10.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Build the card for adding an advisor to the group
  Widget addAdvisor(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Invite New Advisor",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              ColumnBuilder(
                itemCount: nonAdvisorList.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: Key(nonAdvisorList[index].userID),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserDetailsPage(nonAdvisorList[index].userID),
                        ));
                      },
                      child: Container(
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: isSelectedAdvisor[index],
                              onChanged: (bool value) {
                                setState(() {
                                  isSelectedAdvisor[index] = value;
                                  if (value) {
                                    newAdvisorList.add(nonAdvisorList[index]);
                                  } else {
                                    newAdvisorList
                                        .remove(nonAdvisorList[index]);
                                  }
                                });
                              },
                            ),
                            Container(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                //Set the formatting for the name
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: nonAdvisorList[index]
                                                .displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
                                      child: Container(
                                        width: deviceWidth - 156,
                                        //Set the description for every card
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: nonAdvisorList[index].bio,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    NotifyNewAdvisors();
                    setState(() {
                      updateGroupInfo().then((newInfo) {
                        groupInformation = newInfo;
                      });
                    });
                    Flushbar(
                      title: "New Advisors!",
                      message: "We have informed your new advisors!",
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.teal,
                    )..show(context);
                  },
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child: Text('Invite Advisors',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Widget to add moderators to group
  Widget addModerator(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Invite New Moderators",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              ColumnBuilder(
                itemCount: nonModeratorList.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: Key(nonModeratorList[index].userID),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserDetailsPage(nonModeratorList[index].userID),
                        ));
                      },
                      child: Container(
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: isSelectedModerator[index],
                              onChanged: (bool value) {
                                setState(() {
                                  isSelectedModerator[index] = value;
                                  if (value) {
                                    newModeratorList
                                        .add(nonModeratorList[index]);
                                  } else {
                                    newModeratorList
                                        .remove(nonModeratorList[index]);
                                  }
                                });
                              },
                            ),
                            Container(
                              height: 100,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                //Set the formatting for the name
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: nonModeratorList[index]
                                                .displayName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
                                      child: Container(
                                        width: deviceWidth - 156,
                                        //Set the description for every card
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                nonModeratorList[index].bio,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    NotifyNewModerators();
                    setState(() {
                      updateGroupInfo().then((newInfo) {
                        groupInformation = newInfo;
                      });
                    });
                    Flushbar(
                      title: "New Moderators!",
                      message: "We have informed your new moderators!",
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.teal,
                    )..show(context);
                  },
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child: Text('Invite Moderators',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Build the remove posts section
  Widget removePosts(double deviceWidth) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(12.0),
        shadowColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(15.0),
          width: deviceWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
          ),
          constraints: BoxConstraints(minHeight: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Text(
                "Remove Posts",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 2.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              ColumnBuilder(
                itemCount: groupQuestions.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: Key(groupQuestions[index].postID),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => PostPage(
                              groupQuestions[index],
                              groupInformation.groupID,
                              groupQuestions[index].postID,
                              "groups"),
                        ));
                      },
                      child: Container(
                        height: 50.0,
                        child: Row(
                          children: <Widget>[
                            Checkbox(
                              value: isQuestionSelected[index],
                              onChanged: (bool value) {
                                setState(() {
                                  isQuestionSelected[index] = value;
                                  if (value) {
                                    selectedQuestions
                                        .add(groupQuestions[index]);
                                  } else {
                                    newAdvisorList
                                        .remove(groupQuestions[index]);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Container(
                                height: 100,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                  //Set the formatting for the question
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: <Widget>[
                                      RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: groupQuestions[index]
                                                  .question,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                        EdgeInsets.fromLTRB(0, 5, 0, 2),
                                        child: Container(
                                          width: deviceWidth - 156,
                                          //Set the users display name for every card
                                          child: RichText(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: "Posted by " +
                                                      groupQuestions[index]
                                                          .userDisplayName,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  onPressed: () {
                    removePostFromDatabase();
                    setState(() {
                      updateGroupInfo().then((newInfo) {
                        groupInformation = newInfo;
                      });
                    });
                    Flushbar(
                      message: "Posts removed!",
                      duration: Duration(seconds: 5),
                      backgroundColor: Colors.teal,
                    )..show(context);
                  },
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor,
                  child: Text('Remove Posts',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//Build the button for displaying delete group, there must be 0 posts in the group in order for the button to appear.
  Widget deleteGroupBox(double deviceWidth) {
    //If the group has posts in it, display an empty container
    if (groupQuestions.length == 0 || groupQuestions == null)
      return Padding(
        padding: EdgeInsets.all(20.0),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(12.0),
          shadowColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(15.0),
            width: deviceWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
            ),
            constraints: BoxConstraints(minHeight: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  "Delete Group",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 2.0,
                ),
                Text(
                    "WARNING: Deleting a group CAN NOT BE UNDONE. Only press this button if you are sure you want to delete the group."),
                SizedBox(
                  height: 10.0,
                ),
                Center(
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onPressed: () {
                      areYouSureDialog();
                    },
                    padding: EdgeInsets.all(12),
                    color: Theme.of(context).primaryColor,
                    child: Text('Delete Group',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    //Otherwise, build the delete group button
    else {
      return Container();
    }
  }

  //Opens dialog box confirming group deletion
  Future<void> areYouSureDialog() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Deleting ${groupInformation.groupName}"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "You are about to delete ${groupInformation.groupName}!"),
                  Text("\nAre you sure you would like to do this?"),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Yes!"),
                onPressed: () {
                  deleteGroup();
                },
              ),
              FlatButton(
                child: Text("NO!"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  //Future that will handle deleting the group
  Future<void> deleteGroup() async {
    //Query for every user where they are part of the group
    QuerySnapshot queryResult = await Firestore.instance
        .collection('users')
        .where('joinedGroups', arrayContains: groupInformation.groupID)
        .getDocuments();

    //After getting the query, update those user documents to not hold that group anymore
    for (DocumentSnapshot userDoc in queryResult.documents) {
      await userDoc.reference.updateData({
        'joinedGroups': FieldValue.arrayRemove([groupInformation.groupID])
      });
    }

    //Once every user has the group removed from their documents, delete the group itself.
    Firestore.instance
        .collection('groups')
        .document(groupInformation.groupID)
        .delete();

    //Pop back and push a new GroupPage
    //Navigator.popUntil(context, ModalRoute.withName("GroupPage"));
    //Navigator.pushReplacement(context,
    //  MaterialPageRoute(builder: (BuildContext context) => GroupPage()));
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => GroupPage()),
            (Route<dynamic> route) => false);
  }
}