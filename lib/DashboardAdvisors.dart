import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'Dashboard.dart';
import 'MoreMenu.dart';
import 'UserInfor.dart';
import 'QuestionPage.dart';
import 'package:flushbar/flushbar.dart';

import 'pages/MoreQuestions.dart';

//This class handles uploading dashboard questions.
class InviteDashboardAdvisors extends StatefulWidget {
  final selectedTopic;
  final postAnonymously;
  final questionType;
  final multiChoiceList;
  final questionText;
  final descriptionText;
  final responseControllers;
  final image;
  final multipleResponses;

  InviteDashboardAdvisors(
      this.selectedTopic,
      this.postAnonymously,
      this.questionType,
      this.multiChoiceList,
      this.questionText,
      this.descriptionText,
      this.responseControllers,
      this.image,
      this.multipleResponses);

  @override
  _InviteDashboardAdvisorsState createState() =>
      _InviteDashboardAdvisorsState();
}

class _InviteDashboardAdvisorsState extends State<InviteDashboardAdvisors> {
  List<LeaderboardInformation> topUsers = new List();
  String imageURL;
  var _firstPress = true;

  GlobalKey key = GlobalKey();
  var userRanks = new List();

  @override
  void initState() {
    super.initState();
    getTopUsers();
  }

  //Send the advisors a notification when they are asked to participate in a group.
  Future<void> sendDashboardAdvisorsNotification(
      String postID, List<String> dashAdvisors) async {
    final activityFeedRef = Firestore.instance.collection('Notification');

    for (String advisor in dashAdvisors) {
      await activityFeedRef
          .document(advisor)
          .collection("NotificationItems")
          .document()
          .setData({
        "type": "advisorHelp",
        "postID": postID,
        "profileImg": widget.postAnonymously == true
            ? "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/noPictureThumbnail.png?alt=media&token=b7189670-8770-4f85-a51d-936a39b597a1"
            : CurrentUser.profilePicURL,
        "requestor": widget.postAnonymously == true
            ? "Anonymous"
            : CurrentUser.displayName,
        "timestamp": Timestamp.now(),
        "groups_or_topics": "topics",
        "groupOrTopicID": widget.selectedTopic,
      });
    }
    //Navigator.pop(context);
  }

  //Checks if the image is null or if it exists.
  bool ImageNullorExist() {
    if (widget.image == null) {
    } else {
      if (widget.image.existsSync()) {
        return true;
      }
    }
    return false;
  }

  Future<void> uploadImageToDatabase(String documentID) async {
    if (ImageNullorExist()) {
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("postPictures/" + documentID + "postPicture");
      final StorageUploadTask uploadTask =
          pictureNameInStorage.putFile(widget.image);
      await uploadTask.onComplete;

      imageURL = await pictureNameInStorage.getDownloadURL() as String;
    }
  }
  String capitalize(String string) {
    if (string == null) {
      return null;
    }
    if (string.isEmpty) {
      return string;
    }
    return string[0].toUpperCase() + string.substring(1);
  }

  Future<bool> uploadDashboardQuestionToDatabase(
      List<String> invitedAdvisors) async {
    bool noPoints = false;
    DocumentReference newPost = Firestore.instance
        .collection("topics")
        .document(widget.selectedTopic /*.toLowerCase()*/)
        .collection("topicQuestions")
        .document();

    //String to be uploaded into database. Will be "Anonymous" if a user wants to post anonymously.
    String postDisplayName;

    if (invitedAdvisors != null && invitedAdvisors.length > 0) {
      sendDashboardAdvisorsNotification(newPost.documentID, invitedAdvisors);
    }

    //Start by uploading the image to the database, if there is one.
    await uploadImageToDatabase(newPost.documentID);

    //For all posts, incorrect database entry
    if (widget.selectedTopic == "All") {
      newPost = Firestore.instance.collection('posts').document();
    }

    //If posting anonymously, label postDisplayName as "anonymous"
    if (widget.postAnonymously) {
      postDisplayName = "Anonymous";
    } else {
      //Otherwise, postDisplayName is the user's display name
      postDisplayName = CurrentUser.displayName;
    }

    DocumentReference currentUser =
        Firestore.instance.collection('users').document(CurrentUser.userID);

    await Firestore.instance
        .collection('users')
        .document(CurrentUser.userID)
        .get()
        .then((DocumentSnapshot doc) {
      int dailyQuestions = doc["dailyQuestions"];

      if (dailyQuestions > 0) {
        currentUser.updateData({
          'myPosts': FieldValue.arrayUnion([newPost]),
          'dailyQuestions': FieldValue.increment(-1),
        });
      } else {
        noPoints = true;
      }
    });

    if (noPoints) {
      return false;
    }

    switch (widget.questionType) {
      case questionTypes.SHORT_ANSWER:
        {
          await newPost.setData({
            'anonymous': widget.postAnonymously,
            'question': capitalize(widget.questionText),
            'description': capitalize(widget.descriptionText),
            'createdBy': CurrentUser.userID.toString(),
            'userDisplayName': postDisplayName,
            'dateCreated': Timestamp.now(),
            'numOfResponses': 0,
            'likes': {},
            'questionType': questionTypes.SHORT_ANSWER.index,
            'topicName': widget.selectedTopic,
            'views': new List(),
            'reports': {},
            'imageURL': imageURL,
            'multipleResponses': widget.multipleResponses,
          });
        }
        break;
      case questionTypes.MULTIPLE_CHOICE:
        {
          List<String> choices = [];

          for (int i = 0; i < widget.multiChoiceList.length; i++) {
            choices.add(widget.responseControllers[i].text);
          }

           await newPost.setData({
            'anonymous': widget.postAnonymously,
            'question': capitalize(widget.questionText),
            'description': capitalize(widget.descriptionText),
            'choices': choices,
            'createdBy': CurrentUser.userID.toString(),
            'userDisplayName': postDisplayName,
            'dateCreated': Timestamp.now(),
            'numOfResponses': 0,
            'likes': {},
            'questionType': questionTypes.MULTIPLE_CHOICE.index,
            'topicName': widget.selectedTopic,
            'views': new List(),
            'reports': {},
            'imageURL': imageURL,
            'multipleResponses': widget.multipleResponses,
          });
        }
        break;
      case questionTypes.NUMBER_VALUE:
        {
          await newPost.setData({
            'anonymous': widget.postAnonymously,
            'question': capitalize(widget.questionText),
            'description': capitalize(widget.descriptionText),
            'createdBy': CurrentUser.userID.toString(),
            'userDisplayName': postDisplayName,
            'dateCreated': Timestamp.now(),
            'numOfResponses': 0,
            'likes': {},
            'questionType': questionTypes.NUMBER_VALUE.index,
            'topicName': widget.selectedTopic,
            'views': new List(),
            'reports': {},
            'imageURL': imageURL,
            'multipleResponses': widget.multipleResponses,
          });
        }
        break;
    }
    return true;
  }

  Future<void> getTopUsers() async {
    List<LeaderboardInformation> tempTopUsers = new List();

    await Firestore.instance.collection('users').getDocuments().then(
          (QuerySnapshot data) => data.documents.forEach(
            (doc) {
              tempTopUsers.add(new LeaderboardInformation(
                doc.documentID == null ? null : doc.documentID,
                doc["profilePicURL"] == null ? null : doc["profilePicURL"],
                doc["displayName"] == null ? null : doc["displayName"],
                doc["myTopics"] == null ? null : doc["myTopics"],
                doc["earnedPoints"] == null ? 0 : doc["earnedPoints"],
                doc["rank"] == null ? null : doc["rank"],
                false,
              ));
            },
          ),
        );

    setState(() {
      if (tempTopUsers.length > 0) {
        topUsers = sortListByPoints(tempTopUsers);
      }
    });
  }

  /*Sorts list of users by their points, returns a list with 5 of the highest ranked users.
  * Can change the number of users by changing the number in while condition, ex: i<#numberOfTopUsersWanted#*/
  List<LeaderboardInformation> sortListByPoints(
      List<LeaderboardInformation> userList) {
    List<LeaderboardInformation> topFiveUsers = new List();
    int i = 0;

    while (i < 5 && i < userList.length) {
      int maxPoints = 0;

      for (int j = 0; j < userList.length; j++) {
        if (userList[j].id == CurrentUser.userID) {
          userList.removeAt(j);
          j--;
          continue;
        }
        if (userList[maxPoints].totalPoints < userList[j].totalPoints) {
          maxPoints = j;
        }
      }

      String tempRank;
      if (userList[maxPoints].totalPoints < 500)
        tempRank = "Larvae";
      else if (userList[maxPoints].totalPoints >= 500 &&
          userList[maxPoints].totalPoints < 1000)
        tempRank = "Worker Bee";
      else
        tempRank = "Queen Bee";

      userRanks.add(tempRank);
      topFiveUsers.add(new LeaderboardInformation(
          userList[maxPoints].id,
          userList[maxPoints].photoUrl,
          userList[maxPoints].displayName,
          userList[maxPoints].topics,
          userList[maxPoints].totalPoints,
          userList[maxPoints].rank,
          false));
      userList.removeAt(maxPoints);
      i++;
    }

    return topFiveUsers;
  }

  _awaitUpload(BuildContext context, List<String> invitedAdvisors) async {
    bool res= await uploadDashboardQuestionToDatabase(invitedAdvisors);
    if(res) {
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => Dashboard.selectedTopic(null)));
    }else{
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => BuyMoreQuestions()),
      );
    }
  }

  Widget buildTopUserCards(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Expanded(
      child: SizedBox(
        height: 1.0,
        child: ListView.builder(
            itemCount: topUsers.length,
            itemBuilder: (context, index) {
              var userObj = topUsers[index];
              return Card(
                key: Key(userObj.id),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    setState(() {
                      userObj.isSelected = !userObj.isSelected;
                    });
                  },
                  child: Stack(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenSize.width - 50, top: 10),
                        child: Container(
                          height: 50,
                          width: 50,
                          child: Checkbox(
                            value: userObj.isSelected == null
                                ? false
                                : userObj.isSelected,
                            onChanged: (bool value) {
                              setState(() {
                                userObj.isSelected = !userObj.isSelected;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
                          child: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(userObj.photoUrl),
                            minRadius: 30,
                            maxRadius: 30,
                          )),
                      Padding(
                        padding: EdgeInsets.only(left: 73, top: 5, bottom: 5),
                        child: Stack(
                          children: <Widget>[
                            Text(
                              userObj.displayName + "\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                                "\n${userObj.totalPoints} Total Points (${userRanks[index]})"),
                            pickTopThreeTopics(userObj),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  //Function that goes through topic list of user and picks up to their top three topics
  Text pickTopThreeTopics(LeaderboardInformation user) {
    String topics = " No Preference";

    if (user.topics != null && user.topics.length > 0) {
      int i = 0;
      topics = " ";
      while (i < 3 && i < user.topics.length) {
        topics += user.topics[i];
        if (i != 2 && i != user.topics.length - 1) topics += ", ";

        i++;
      }
    }

    return Text("\n\nTopics:$topics");
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Invite Advisors"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        heroTag: "dashboardAdvisorHero1",
        onPressed: () {
          if (_firstPress) {
            _firstPress = false;
            List<String> invitedAdvisors = new List();
            for (int i = 0; i < topUsers.length; i++) {
              if (topUsers[i].isSelected == true)
                invitedAdvisors.add(topUsers[i].id);
            }
            _awaitUpload(context, invitedAdvisors);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(3, context, key, false),
      body: topUsers == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildTopUserCards(context),
              ],
            ),
    );
  }
}
