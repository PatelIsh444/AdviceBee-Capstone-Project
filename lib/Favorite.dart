import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import './utils/displayQuestionCard.dart';
import 'package:flutter/material.dart';
import 'QuestionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MoreMenu.dart';

class FavoritePage extends StatefulWidget {
  @override
  FavoritePageState createState() => FavoritePageState();
}

class FavoritePageState extends State<FavoritePage> {
  //Variables
  List<String> topicOrGroup = [];
  List<questions> postInfoList = [];
  List<String> groupIDs = [];
  int currentTab = 3;
  GlobalKey key = GlobalKey();
  var _userCreated = false;
  Future<List<questions>> getPostsFuture;

  void initState() {
    super.initState();
    getPostsFuture = getPosts();
  }

  Future<List<questions>> getPosts() async {
    //Create local list
    List<questions> postInfo = new List();

    for (DocumentReference post in CurrentUser.favoritePosts) {

      var referencePathSplit = post.path.split("/");
      groupIDs.add(referencePathSplit[1]);
      topicOrGroup.add(referencePathSplit[0]);
      try{
        await post
            .get()
            .then((DocumentSnapshot doc) {
          switch (questionTypes.values[doc["questionType"] as int]) {
            case questionTypes.SHORT_ANSWER:
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
                  doc["topicName"]== null ? null : doc["topicName"],
                  doc["likes"],
                  doc["views"],
                  doc["reports"],
                  doc["anonymous"],
                  doc["multipleResponses"] == null ? false : doc["multipleResponses"],
                  doc["imageURL"] == null ? null : doc["imageURL"],
                ));
                break;
              }
            case questionTypes.MULTIPLE_CHOICE:
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
                  doc["topicName"]==null ? null : doc["topicName"],
                  doc["likes"],
                  doc["views"],
                  doc["reports"],
                  doc["anonymous"],
                  doc["multipleResponses"] == null ? false : doc["multipleResponses"],
                  doc["imageURL"] == null ? null : doc["imageURL"],
                ));
                break;
              }
            case questionTypes.NUMBER_VALUE:
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
                  doc["topicName"]==null ? null : doc["topicName"],
                  doc["likes"],
                  doc["views"],
                  doc["reports"],
                  doc["anonymous"],
                  doc["multipleResponses"] == null ? false : doc["multipleResponses"],
                  doc["imageURL"] == null ? null : doc["imageURL"],
                ));
                break;
              }
          }
        });
      }
      catch(exception){
        continue;
    }
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
                          return new PostPage(questionObj, groupIDs[index],
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child:
                  displayQuestionCard(questionObj.question,questionObj.questionDescription,"general"),

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
                          return new PostPage(questionObj, groupIDs[index],
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child:
                  displayQuestionCard(questionObj.question,questionObj.questionDescription,"mchoice"),


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
                          return new PostPage(questionObj, groupIDs[index],
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
                  "You haven't posted anything!",
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
      "Favorite is Empty",
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0),
    ),
  );
  final notificationText = Text(
    "You haven't saved anything yet. Tap the bookmark icon on questions to save them for later.",
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
      color: Colors.grey.withOpacity(0.6),
    ),
    textAlign: TextAlign.center,
  );

  buildNoFavoritePost() {

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
        future: getPostsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<questions>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Scaffold(
                floatingActionButton:
                FloatingActionButton(
                  onPressed: () {
                  },
                  heroTag: "holdingFavs1",
                  tooltip: 'Increment',
                  child: CircleAvatar(
                    child: Image.asset(
                      'images/addPostIcon4.png',
                    ),
                    maxRadius: 12,
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
                  heroTag: "holding2",
                  tooltip: 'Increment',
                  child: CircleAvatar(
                    child: Image.asset(
                      'images/addPostIcon4.png',
                    ),
                    maxRadius: 12,
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasData && snapshot.data.isNotEmpty) {
                postInfoList = snapshot.data;
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("Favorite Posts"),
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
                    heroTag: "favsHero",
                    tooltip: 'Increment',
                    child: CircleAvatar(
                      child: Image.asset(
                        'images/addPostIcon4.png',
                      ),
                      maxRadius: 12,
                    ),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                );
              } else {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("Favorite Posts"),
                  ),
                  body:ListView(children: buildNoFavoritePost()),
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
                    heroTag: "favs2PostsHero",
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