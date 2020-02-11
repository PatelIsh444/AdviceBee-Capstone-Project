import './utils/displayQuestionCard.dart';
import 'package:flutter/material.dart';
import 'QuestionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './user.dart';
import 'MoreMenu.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './utils/commonFunctions.dart';
import 'Dashboard.dart';

class OtherUserPostPage extends StatefulWidget {
  final otherUserID;
  final otherUserPosts;
  OtherUserPostPage(this.otherUserID, this.otherUserPosts);

  @override
  OtherUserPostPageState createState() => OtherUserPostPageState();
}

class OtherUserPostPageState extends State<OtherUserPostPage> {
  //Variables
  var referencePathSplit;
  List<String> topicOrGroup = [];
  List<questions> postInfoList = [];
  List<String> groupIDs = [];
  var userID;
  int currentTab = 3;
  GlobalKey key = GlobalKey();

  var _userCreated = false;
  List<String> userQuestionGroupIDs = [];
  Future<List<questions>> getPostsFuture;
  Future<List<questions>> getProfilePostsFuture;

  void initState() {
    super.initState();
    getProfilePostsFuture = getPosts(widget.otherUserPosts);
  }

  Future<List<questions>> getPosts(List<dynamic> postRefs) async {
    //Create local list
    List<questions> postInfo = new List();
    //For each post reference from the user, get the post information
    for (int i = 0; i < postRefs.length; i++) {
      DocumentReference post = postRefs[i] as DocumentReference;
      var referencePathSplit = post.path.split("/");
      topicOrGroup.add(referencePathSplit[0]);
      userQuestionGroupIDs.add(referencePathSplit[1]);
      print(topicOrGroup[i]);
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
                doc["topicName"] == null ? userQuestionGroupIDs[i] : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"],
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
                doc["topicName"] == null ? userQuestionGroupIDs[i] : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"],
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
                doc["topicName"] == null ? userQuestionGroupIDs[i] : doc["topicName"],
                doc["likes"],
                doc["views"],
                doc["reports"],
                doc["anonymous"],
                doc["multipleResponses"],
                doc["imageURL"] == null ? null : doc["imageURL"],
              ));
              break;
            }
        }
      });
    }
    return postInfo;
  }

  Widget buildPostCards()
  {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
          itemCount: postInfoList.length,
          itemBuilder: (context, index) {
            var questionObj = postInfoList[index];

            if (questionObj is basicQuestionInfo) {
              return Card(
                key: Key(questionObj.postID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return new PostPage(questionObj,
                              questionObj.topic,
                              questionObj.postID,
                              topicOrGroup[index]);
                        }));
                  },
                  child:displayQuestionCard(questionObj.question,questionObj.questionDescription,"general"),
                ),
              );
            }
            if (questionObj is MultiChoiceQuestion) {
              return Card(
                key: Key(questionObj.postID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return new PostPage(questionObj,
                              questionObj.topic,
                              questionObj.postID,
                              topicOrGroup[index]);
                        }));
                  },
                  child: displayQuestionCard(questionObj.question,questionObj.questionDescription,"mchoice"),
                ),
              );
            } else if (questionObj is NumberValueQuestion) {
              return Card(
                key: Key(questionObj.postID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {


                          return new PostPage(questionObj, questionObj.topic,
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child: displayQuestionCard(questionObj.question,questionObj.questionDescription,"number"),
                ),
              );
            } else {
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "No Posts Available!",
                  textAlign: TextAlign.center,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  final image = Image.asset('images/empty.png');

  final notificationHeader = Container(
    padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
    child: Text(
      "No Posts Yet",
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0),
    ),
  );
  final notificationText = Text(
    "Share your Advice!",
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
      color: Colors.grey.withOpacity(0.6),
    ),
    textAlign: TextAlign.center,
  );

  buildEmptyPost() {

    return <Widget>[SizedBox(
      height: 40.0,
    ),
      Padding(
        padding: EdgeInsets.only(
          top: 70.0,
          left: 30.0,
          right: 30.0,
          bottom: 30.0,),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[image, notificationHeader, notificationText],
        ),
      ),];

  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<questions>>(
        future: getProfilePostsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<questions>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Scaffold(
                floatingActionButton:
                FloatingActionButton(
                  onPressed: () {
                  },
                  heroTag: "otherPostsHero3",
                  tooltip: 'Increment',
                  child: CircleAvatar(
                    child: Image.asset(
                      'images/addPostIcon4.png',
                    ),
                    maxRadius: 18,
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Scaffold(
                floatingActionButton:
                FloatingActionButton(
                  onPressed: () {
                  },
                  heroTag: "otherPostsHero4",
                  tooltip: 'Increment',
                  child: CircleAvatar(
                    child: Image.asset(
                      'images/addPostIcon4.png',
                    ),
                    maxRadius: 18,
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasData  && snapshot.data.isNotEmpty) {
                postInfoList = snapshot.data;
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: AutoSizeText("Posts"),
                    centerTitle: true,
                  ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildPostCards(),
                    ],
                  ),
                  floatingActionButton:
                  FloatingActionButton(
                    onPressed: () {
                      if (CurrentUser.isNotGuest) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => postQuestion(null, null) //AddPost(),
                            ));
                      } else{
                        guestUserSignInMessage(context);
                      }
                    },
                    heroTag: "otherPostsHero5",
                    tooltip: 'Increment',
                    child: CircleAvatar(
                      child: Image.asset(
                        'images/addPostIcon4.png',
                      ),
                      maxRadius: 18,
                    ),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                );
              } else {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("Posts"),
                    centerTitle: true,
                  ),
                  body: ListView(children: buildEmptyPost(),
                  ),
                  floatingActionButton:
                  FloatingActionButton(
                    onPressed: () {
                      if (CurrentUser.isNotGuest) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => postQuestion(null, null) //AddPost(),
                            ));
                      } else{
                        guestUserSignInMessage(context);
                      }
                    },
                    heroTag: "otherPostsHero6",
                    tooltip: 'Increment',
                    child: CircleAvatar(
                      child: Image.asset(
                        'images/addPostIcon4.png',
                      ),
                      maxRadius: 18,
                    ),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                );
              }
          }
          return null;
        });
  }
}