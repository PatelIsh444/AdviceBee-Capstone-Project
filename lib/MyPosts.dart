import 'package:v0/utils/editPost.dart';
import 'Dashboard.dart';
import 'package:flutter/material.dart';
import 'QuestionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MoreMenu.dart';
import './utils/commonFunctions.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flushbar/flushbar.dart';

/*
 *  This class displays user's own posts
 *  User should be able to edit and delete a post on this page
 */

class MyPostPage extends StatefulWidget {
  @override
  MyPostPageState createState() => MyPostPageState();
}

class MyPostPageState extends State<MyPostPage> {
  //Variables
  var referencePathSplit;
  List<String> topicOrGroup = [];
  List<questions> postInfoList = [];
  List<String> groupIDs = [];
  int currentTab = 3;
  GlobalKey key = GlobalKey();

  //FireBase reference to the user document
  final userDataDocumentRef =  Firestore.instance
      .collection('users')
      .document(CurrentUser.userID);

  var _userCreated = false;
  Future<List<questions>> getPostsFuture;

  void initState() {
    super.initState();
    getPostsFuture = getPosts();
  }

  Future<List<questions>> getPosts() async {
    //Create local list
    List<questions> postInfo = new List();
    await userDataDocumentRef
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        if (ds.data["myPosts"]!=null) {
          CurrentUser.myPosts=ds.data["myPosts"];
        }
      });
    });
    /**
     *  Refactor Questions classes
     */
    for (DocumentReference post in CurrentUser.myPosts) {
      referencePathSplit = post.path.split("/");
      topicOrGroup.add(referencePathSplit[0]);
      groupIDs.add(referencePathSplit[1]);
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
    return postInfo;
  }

  Widget buildPostCards()
  {
    String groupOrTopic;
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
                          return PostPage(questionObj, groupIDs[index],
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child:displayMyPost(questionObj,index,"general"),
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
                          return PostPage(questionObj, groupIDs[index],
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child: displayMyPost(questionObj,index,"mchoice"),
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
                          return  PostPage(questionObj, groupIDs[index],
                              questionObj.postID, topicOrGroup[index]);
                        }));
                  },
                  child: displayMyPost(questionObj,index, "number"),
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
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<questions>>(
        future: getPostsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<questions>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return loadingScaffold(currentTab, context, key, true, "middleButtonHold1");
            case ConnectionState.active:
            case ConnectionState.waiting:
              return loadingScaffold(currentTab, context, key, true, "middleButtonHold2");
            case ConnectionState.done:
              if (snapshot.hasData  && snapshot.data.isNotEmpty) {
                postInfoList = snapshot.data;
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("My Posts"),
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
                    heroTag: "my2PostsHero",
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
                    title: Text("My Posts"),
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
                    heroTag: "my1PostsHero",
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

  Widget _getImageByType(String type){
    switch(type) {
      case "general":{return Image(image: AssetImage('images/basic.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);}
      case "mchoice":{return Image(image: AssetImage('images/choice.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);}
      case "number":{return Image(image: AssetImage('images/statistic.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);}
      default:{return Container();}
    }
  }

  Widget _getColumnText(String title,String description){
    return new Expanded(
        child: new Container(
          margin: new EdgeInsets.all(10.0),
          child: new Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: <Widget>[
              _getTitleWidget(title),
              _getDescriptionWidget(description)],
          ),
        )
    );
  }

  Widget _getTitleWidget(String title){
    return Text(
      title,
      maxLines: 1,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _getDescriptionWidget(String description){
    return Container(
      margin: EdgeInsets.only(top: 5.0),
      child: AutoSizeText("$description",maxLines: 1,),
    );
  }


  Widget displayMyPost(var questionObj, int index, String questionType) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _getImageByType(questionType),
          _getColumnText(questionObj.question,questionObj.questionDescription),
        ],
      ),
      //actions: <Widget>[],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Edit',
          color: Colors.black45,
          icon: Icons.edit,
          onTap: (){_edit(questionObj, index);},
        ),
        IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: (){ _confirmDelete(questionObj,index);}
        ),
      ],
    );
  }
  _confirmDelete(var questionObj,int index) {
    showDialog(
        context: context,
        builder: (context)=> AlertDialog(
          title: Text("Are you sure you want to delete this post?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Yes"),
              onPressed:()=> _deletePost(questionObj, index),
            ),
            FlatButton(
              child: Text("No"),
              onPressed: ()=>Navigator.pop(context),
            )
          ],
        ),
    );
  }

  _edit(var questionObj, int index) {
    if (questionObj.numOfResponses!=0) {
      Flushbar(
        title: "Editing Failed",
        message: "You can't edit a post that has been responded",
        duration: Duration(seconds: 5),
        backgroundColor: Colors.teal,
      ).show(context);
    }else {
      Flushbar(
        title: "Success",
        message: "Edited successful",
        duration: Duration(seconds: 5),
        backgroundColor: Colors.teal,
      ).show(context);
      setState(() {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) {
              return editPost(
                questionObj, topicOrGroup.elementAt(index),groupIDs.elementAt(index),
              );
            })
        );
      });
    }
  }
  _deletePost(var questionObj,int index){
    print("deleted");
    Navigator.pop(context);
    Flushbar(
      title: "Success",
      message: "Post deleted successful",
      duration: Duration(seconds: 8),
      backgroundColor: Colors.teal,
    ).show(context);
    setState(() {
      postInfoList.removeAt(index);
    });
  }
}