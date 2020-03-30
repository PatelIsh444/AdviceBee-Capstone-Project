import 'package:intl/intl.dart';

import 'QuestionPage.dart';
import 'User.dart';
import './utils/displayQuestionCard.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'MoreMenu.dart';
import 'package:line_icons/line_icons.dart';
import 'Dashboard.dart';
import 'Profile.dart' as cProfile;
import 'OtherUserPosts.dart';
import 'OtherUserFollowerPage.dart';
import './utils/commonFunctions.dart';
import 'pages/Chat.dart';
import 'pages/FullPhoto.dart';
import 'pages/NewChat.dart';

class UserDetailsPage extends StatefulWidget {
  String userID;
  User userInfo;

  UserDetailsPage(this.userID);

  //UserDetailsPage.withInstance(this.userInfo);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  //Variables
  Future<User> userInformationFuture;
  User userInformation;

  String title = "";
  bool isFollowed = false;
  String scores = "100";
  String rank = "Larvae222f";
  String tempUserID;
  int numberOfFollowers = 0;
  int numberOfFollowing = 0;
  String lastAccess = " ";
  List<questions> userQuestions;
  List<String> userQuestionGroupIDs = [];
  List<String> topicOrGroup = [];
  List<User> blocked = [];
  String rankImage =
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
      "appspot.com/o/rankIcons%2FLarvae.png?alt=media&token=9afeb4c7-dbaf-"
      "4f8f-9885-3906155ed612";
  String dateJoined = "October 2019";
  GlobalKey key = GlobalKey();

  //Stores the text used in the button for follow/unfollow
  String buttonText;

  @override
  void initState() {
    super.initState();
    if (widget.userInfo != null) {
      userInformation = widget.userInfo;
    } else {
      userInformationFuture = getUserInformation(widget.userID);
    }
  }

  Future<void> setRank() async {
    int tempScores = int.parse(scores);
    if (tempScores < 500) {
      rank = "Larvae";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2FLarvae.png?alt=media&token=9afeb4c7-dbaf-"
          "4f8f-9885-3906155ed612";
    } else if (tempScores >= 500 && tempScores < 1000) {
      rank = "Worker Bee";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2Fbee.png?alt=media&token=80bd21e2-f795-"
          "46f4-a273-4d5653dfa414";
    } else {
      rank = "Queen Bee";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2FqueenBee2.png?alt=media&token=c4b425ed-"
          "76c8-44fb-a933-5ca00031168b";
    }
    Firestore.instance
        .collection('users')
        .document(tempUserID)
        .updateData({'rank': rank});
  }

  bool currentUserFollowingProfile() {
    return userInformation.followers.contains(CurrentUser.userID);
  }

  //Function for getting user's information
  Future<User> getUserInformation(String passedUserID) async {
    User userInfo = new User();

    await Firestore.instance
        .collection('users')
        .document(passedUserID)
        .get()
        .then((DocumentSnapshot doc) {
      userInfo.displayName = doc["displayName"];
      userInfo.email = doc["email"];
      userInfo.userID = doc.documentID;
      userInfo.profilePicURL = doc["profilePicURL"];
      userInfo.myPosts = doc["myPosts"];
      userInfo.favoritePosts = doc["favoritePosts"];
      userInfo.joinedGroups = doc["joinedGroups"];
      userInfo.followers = doc["followers"];
      userInfo.following = doc["following"];
      userInfo.likedPosts = doc["likedPosts"];
      userInfo.bio = doc["bio"];
      userInfo.dailyPoints = doc["dailyPoints"];
      userInfo.earnedPoints = doc["earnedPoints"];
      if (doc['last access'] != null) {
        if (doc['last access'].toString() == "online") {
          lastAccess = "Online";
        } else {
          lastAccess = "Last access: " +
              DateFormat('dd MMM kk:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      int.parse(doc['last access'])));
        }
      }
      userInfo.blocked = doc["blocked"];
      setState(() {
        if (doc["title"] != null) {
          title = doc["title"];
        }
        if (doc["dateCreated"] != null) {
          DateTime timeStampSplit = (doc["dateCreated"]).toDate();
          dateJoined = cProfile.getMonth(timeStampSplit.month) +
              timeStampSplit.year.toString();
          print(dateJoined);
        }
        scores = (userInfo.dailyPoints + userInfo.earnedPoints).toString();
        tempUserID = userInfo.userID;
        if (userInfo.followers != null) {
          numberOfFollowers = userInfo.followers.length;
        }
        if (userInfo.following != null) {
          numberOfFollowing = userInfo.following.length;
        }
      });
    });

    setRank();
    return userInfo;
  }

  Stream getUserInformationStream(String passedUserID) {
    return Firestore.instance
        .collection('users')
        .document(passedUserID)
        .snapshots();
  }

  //Function maps snapshot data to User class
  void createUserClass(AsyncSnapshot snapshot) {
    userInformation = new User.fromDocument(snapshot.data);
  }

  //Get the information for the users posts from the database
  Future<List<questions>> getProfilePosts(List<dynamic> postRefs) async {
    //Create local list
    List<questions> postInfo = new List();
    //For each post reference from the user, get the post information
    for (int i = 0; i < postRefs.length; i++) {
      DocumentReference post = postRefs[i] as DocumentReference;
      var referencePathSplit = post.path.split("/");
      topicOrGroup.add(referencePathSplit[0]);
      userQuestionGroupIDs.add(referencePathSplit[1]);
      await post.get().then((DocumentSnapshot doc) {
        switch (doc["questionType"]) {
          case 0:
            {
              postInfo.add(new basicQuestionInfo(
                doc.documentID,
                doc["question"],
                doc["description"],
                doc["createdBy"],
                doc["userDisplayName"],
                doc["dateCreated"],
                doc["numOfResponses"],
                doc["questionType"],
                doc["topicName"] == null ? null : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"] == null
                    ? false
                    : doc["multipleResponses"],
                doc["imageURL"] == null ? null : doc["imageURL"],
              ));
              break;
            }
          case 1:
            {
              postInfo.add(new MultiChoiceQuestion(
                doc.documentID,
                doc["question"],
                doc["description"],
                doc["createdBy"],
                doc["userDisplayName"],
                doc["dateCreated"],
                doc["numOfResponses"],
                doc["questionType"],
                doc["choices"],
                doc["topicName"] == null ? null : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"] == null
                    ? false
                    : doc["multipleResponses"],
                doc["imageURL"] == null ? null : doc["imageURL"],
              ));
              break;
            }
          case 2:
            {
              postInfo.add(new NumberValueQuestion(
                doc.documentID,
                doc["question"],
                doc["description"],
                doc["createdBy"],
                doc["userDisplayName"],
                doc["dateCreated"],
                doc["numOfResponses"],
                doc["questionType"],
                doc["topicName"] == null ? null : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"] == null
                    ? false
                    : doc["multipleResponses"],
                doc["imageURL"] == null ? null : doc["imageURL"],
              ));
              break;
            }
        }
      });
    }
    return postInfo;
  }

  @override
  Widget build(BuildContext context) {
    if (userInformation != null) {
      return StreamBuilder(
        stream: getUserInformationStream(userInformation.userID),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            createUserClass(snapshot);
            //Create the user class from the snapshot
            isFollowed = currentUserFollowingProfile();
            //Build the UI
            return buildUserProfile();
          } else {
            //Otherwise show a progress indicator for loading
            return loadingScaffold(3, context, key, false, "middleButtonHold9");
          }
        },
      );
    } else {
      return StreamBuilder(
        stream: getUserInformationStream(widget.userID),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            createUserClass(snapshot);
            //Create the user class from the snapshot
            isFollowed = currentUserFollowingProfile();
            //Build the UI
            return buildUserProfile();
          } else {
            //Otherwise show a progress indicator for loading
            return loadingScaffold(3, context, key, false, "middleButtonHold6");
          }
        },
      );
    }
  }

  Widget buildRank(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                image: new DecorationImage(
                  image: new CachedNetworkImageProvider(rankImage),
                  //fit: BoxFit.cover,
                ),
                //borderRadius: BorderRadius.circular(80.0),
              ),
            ),
            Text(
              " " + rank + " ",
              style: TextStyle(
                fontFamily: 'Spectral',
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                image: new DecorationImage(
                  image: new CachedNetworkImageProvider(rankImage),
                  //fit: BoxFit.cover,
                ),
                //borderRadius: BorderRadius.circular(80.0),
                /*border: Border.all(
              color: Colors.black,
              width: 5.0,
            ),*/
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatContainer() {
    return Container(
      height: 60.0,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFFEFF4F7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildScoreBar("Followers", numberOfFollowers.toString()),
          buildScoreBar("Following", numberOfFollowing.toString()),
          buildScoreBar(
              "Posts",
              userInformation.myPosts == null
                  ? "0"
                  : userInformation.myPosts.length.toString()),
          buildScoreBar("Points", scores),
        ],
      ),
    );
  }

  Widget buildScoreBar(String label, String count) {
    TextStyle statLabelTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w200,
    );

    TextStyle statCountTextStyle = TextStyle(
      color: Colors.black54,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    );

    Size screenSize = MediaQuery.of(context).size;
    return InkWell(
        onTap: () {
          if (label == "Points") {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return cProfile.rankInformationMessage(context);
                });
          } else if (label == "Followers") {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new OtherUserFollowingFollowersPage(
                  0, userInformation.userID);
            }));
          } else if (label == "Following") {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new OtherUserFollowingFollowersPage(
                  1, userInformation.userID);
            }));
          } else if (label == "Posts") {
            print(userInformation.userID);
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new OtherUserPostPage(
                  userInformation.userID, userInformation.myPosts);
            }));
          } else {
            print("Unknown Statbar button click");
          }
        },
        child: Container(
            width: screenSize.width / 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  count,
                  style: statCountTextStyle,
                ),
                Text(
                  label,
                  style: statLabelTextStyle,
                ),
              ],
            )));
  }

  Widget buildUserProfile() {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text("Profile"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (CurrentUser.isNotGuest) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => postQuestion(null, null) //AddPost(),
                    ));
          } else {
            guestUserSignInMessage(context);
          }
        },
        heroTag: "newProfilefeHero",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 18,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(0, context, key, false),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            userImage(deviceWidth),
            userName(),
            buildJobTitle(context),
            buildRank(context),
            buildStatContainer(),
            buildDate(context),
            aboutUser(deviceWidth),
            userOnlineStatus(),
            buildSeparator(deviceWidth),
            SizedBox(height: 10.0),
            CurrentUser.isNotGuest && CurrentUser.userID != widget.userID
                ? getFollowButton()
                : Container(),
            SizedBox(height: 10.0),
            CurrentUser.isNotGuest &&
                    CurrentUser.userID != widget.userID &&
                    !userInformation.blocked.contains(CurrentUser.userID)
                ? getChatButton()
                : Container(),
            SizedBox(height: 30.0),
            //userPosts(deviceWidth),
            //SizedBox(height: 30,)
          ],
        ),
      ),
    );
  }

  Widget buildSeparator(double screenSize) {
    return Center(
      child: Container(
        width: screenSize / 1.6,
        height: 2.0,
        color: Colors.black54,
        margin: EdgeInsets.only(top: 4.0),
      ),
    );
  }

  //Shows the latest posts from the user
  Widget userPosts(double deviceWidth) {
    //Get myPosts information for this user's profile
    Future<List<questions>> getProfilePostsFuture =
        getProfilePosts(userInformation.myPosts);

    return FutureBuilder<List<questions>>(
      future: getProfilePostsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<questions>> snapshot) {
        //If future has finished then...
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return loadingScaffold(3, context, key, false, "middleButtonHold7");
          case ConnectionState.active:
          case ConnectionState.waiting:
            return loadingScaffold(3, context, key, false, "middleButtonHold8");
          case ConnectionState.done:
            if (snapshot.hasData) {
              userQuestions = snapshot.data;
              return Padding(
                padding: EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(12.0),
                  shadowColor: Colors.white,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
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
                          height: 6.0,
                        ),
                        Text(
                          userInformation.displayName + "'s Posts:",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 3.0,
                        ),
                        buildMyPostsCard(),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              //Otherwise show a progress indicator for loading
              return loadingScaffold(
                  3, context, key, false, "middleButtonHold10");
            }
        }
        return null; //Unreachable
      },
    );
  }

  Widget buildMyPostsCard() {
    return ColumnBuilder(
        itemCount: userQuestions.length,
        itemBuilder: (context, index) {
          var userObj = userQuestions[index];
          return Card(
            elevation: 5,
            child: new InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return new PostPage(
                    userQuestions[index],
                    userQuestionGroupIDs[index],
                    userQuestions[index].postID,
                    topicOrGroup[index],
                  );
                }));
              },
              child: displayQuestionCard(userQuestions[index].question,
                  userQuestions[index].questionDescription, "profile"),
            ),
          );
        });
  }

  //Build the user name section
  Widget userName() {
    TextStyle nameTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black,
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
    );

    return Center(
      child: AutoSizeText(
        userInformation.displayName,
        style: nameTextStyle,
        maxLines: 1,
      ),
    );
  }

  Widget userOnlineStatus() {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.bold, //try changing weight to w500 if not thin
      fontSize: 16.0,
    );
    return Center(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                lastAccess,
                textAlign: TextAlign.center,
                style: bioTextStyle,
              ),
              lastAccess == "Online"
                  ? CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 10.0,
                      backgroundImage: AssetImage('assets/onlineGreenDot.jpg'))
                  : CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: 10.0,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget userImage(double deviceWidth) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      FullPhoto(url: userInformation.profilePicURL)));
        },
        child: Hero(
          tag: "image",
          child: Container(
            width: 160.0,
            height: 160.0,
            decoration: BoxDecoration(
              image: new DecorationImage(
                image: new CachedNetworkImageProvider(
                    userInformation.profilePicURL),
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
      ),
    );
  }

  Widget cancelBtn() {
    return Positioned(
      top: 50.0,
      left: 20.0,
      child: Container(
        height: 35.0,
        width: 35.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.5),
        ),
        child: IconButton(
          icon: Icon(
            LineIcons.close,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          iconSize: 20.0,
        ),
      ),
    );
  }

  Widget userPoints() {
    return Container(
      padding: EdgeInsets.only(left: 20.0, right: 20.0),
      child: Text(
        "Total Points ${userInformation.dailyPoints + userInformation.earnedPoints}",
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.grey.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget buildJobTitle(BuildContext context) {
    if (title == null || title.length < 1) return Container();

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Spectral',
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget buildDate(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.bold, //try changing weight to w500 if not thin
      fontSize: 16.0,
    );

    return Center(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Member Since $dateJoined",
          textAlign: TextAlign.center,
          style: bioTextStyle,
        ),
      ),
    );
  }

  Widget aboutUser(double deviceWidth) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w400, //try changing weight to w500 if not thin
      color: Color(0xFF799497),
      fontSize: 16.0,
    );

    return Center(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(8.0),
        child: Text(
          userInformation.bio,
          textAlign: TextAlign.center,
          style: bioTextStyle,
        ),
      ),
    );
  }

  Widget getChatButton() {
    return Center(
      child: InkResponse(
        onTap: () async {
          String groupChatId = '';
          String peerIdLocal = userInformation.userID;
          User peerLocal = userInformation;
          String currentUserId = CurrentUser.userID;
          User currentUser = CurrentUser;
          if (currentUserId.hashCode <= peerIdLocal.hashCode) {
            groupChatId = "$currentUserId-$peerIdLocal";
          } else {
            groupChatId = "$peerIdLocal-$currentUserId";
          }
          DocumentSnapshot doc = await Firestore.instance
              .collection('chats')
              .document(groupChatId)
              .get();
          if (doc == null || !doc.exists) {
            Firestore.instance
                .collection('chats')
                .document(groupChatId)
                .setData({
              'id': currentUserId,
              'displayName': currentUser.displayName,
              'profilePicURL': currentUser.profilePicURL,
              'bio': currentUser.bio,
              'peerBio': peerLocal.bio,
              'peerNickname': peerLocal.displayName,
              'peerPhotoUrl': peerLocal.profilePicURL,
              'peerId': peerLocal.userID,
              'approved': false,
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => NewChatScreen(
                        currentUserId: CurrentUser.userID,
                      )),
            );
          } else {
            if (doc['approved'] == false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => NewChatScreen(
                          currentUserId: CurrentUser.userID,
                        )),
              );
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Chat(
                            userId: currentUserId,
                            chatId: groupChatId,
                            peerId: userInformation.userID,
                            peerAvatar: userInformation.profilePicURL,
                            peerName: userInformation.displayName,
                          )));
            }
          }
        },
        child: Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            height: 40.0,
            decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(20.0)),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    "Message",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getFollowButton() {
    if (isFollowed) {
      buttonText = "Unfollow";
    } else {
      buttonText = "Follow";
    }

    return Center(
      child: InkResponse(
        onTap: () {
          updateFollowers();
        },
        child: Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Container(
            height: 40.0,
            decoration: BoxDecoration(
                color: Colors.teal, borderRadius: BorderRadius.circular(20.0)),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateFollowers() async {
    DocumentReference currentUserRef =
        Firestore.instance.collection('users').document(CurrentUser.userID);
    DocumentReference currentProfileRef =
        Firestore.instance.collection('users').document(userInformation.userID);

    if (isFollowed) {
      await currentUserRef.updateData({
        'following': FieldValue.arrayRemove([userInformation.userID]),
      });
      await currentProfileRef.updateData({
        'followers': FieldValue.arrayRemove([CurrentUser.userID]),
      });

      isFollowed = !isFollowed;
      setState(() {
        numberOfFollowers--;

        //this.userInformation = userInformation;
      });
    } else {
      await currentUserRef.updateData({
        'following': FieldValue.arrayUnion([userInformation.userID]),
      });
      await currentProfileRef.updateData({
        'followers': FieldValue.arrayUnion([CurrentUser.userID]),
      });

      isFollowed = !isFollowed;
      setState(() {
        numberOfFollowers++;
        //this.userInformation = userInformation;
      });
    }
  }
}
