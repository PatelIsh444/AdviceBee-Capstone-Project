import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'Dashboard.dart';
import 'DashboardAdvisors.dart';
import './utils/commonFunctions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'User.dart';
import 'pages/FullPhoto.dart';
import 'responsePage.dart';
import 'MoreMenu.dart';
import 'newProfile.dart' as profile;
import 'Charts.dart';
import './utils/MultiSelectChip.dart';

class MultipleChoiceEntry {
  final key = UniqueKey();

  Widget buildMultipleChoiceEntry(TextEditingController textController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: new TextFormField(
        controller: textController,
        decoration: new InputDecoration(labelText: 'Response'),
        //autovalidate: true,
        validator: (value) {
          if (value.isEmpty) return "Please enter a response";
          return null;
        },
        maxLength: 60,
        onSaved: (value) {
          textController.text = value;
        },
      ),
    );
  }
}

abstract class questions {
  final String postID;
  final String question;
  final String questionDescription;
  final String createdBy;
  final String userDisplayName;
  final Timestamp datePosted;
  final int numOfResponses;
  final int questionType;
  final Map likes;
  bool heart = false;
  bool star = false;
  final String topic;
  List<dynamic> views;
  final Map reports;
  final bool anonymous;
  final bool multipleResponses;
  final String imageURL;
  String thumbnailURL;

  questions(
    this.postID,
    this.question,
    this.questionDescription,
    this.createdBy,
    this.userDisplayName,
    this.datePosted,
    this.numOfResponses,
    this.questionType,
    this.topic,
    this.likes,
    this.reports,
    this.anonymous,
    this.multipleResponses,
    this.imageURL,
  );
}

class basicQuestionInfo implements questions {
  final String postID;
  final String question;
  final String questionDescription;
  final String createdBy;
  final String userDisplayName;
  final Timestamp datePosted;
  final int numOfResponses;
  final int questionType;
  final Map likes;
  bool heart = false;
  bool star = false;
  final String topic;
  List<dynamic> views;
  final Map reports;
  final bool anonymous;
  final bool multipleResponses;
  final String imageURL;
  String thumbnailURL;

  basicQuestionInfo(
    this.postID,
    this.question,
    this.questionDescription,
    this.createdBy,
    this.userDisplayName,
    this.datePosted,
    this.numOfResponses,
    this.questionType,
    this.topic,
    this.likes,
    this.views,
    this.reports,
    this.anonymous,
    this.multipleResponses,
    this.imageURL,
  );
}

//Basic multiple Choice question info pulled from database
class MultiChoiceQuestion implements questions {
  final String postID;
  final String question;
  final String questionDescription;
  final String createdBy;
  final String userDisplayName;
  final Timestamp datePosted;
  final int numOfResponses;
  final int questionType;
  final List<dynamic> multipleChoiceAnswers;
  final Map likes;
  bool heart = false;
  bool star = false;
  final String topic;
  List<dynamic> views;
  final Map reports;
  final bool anonymous;
  final bool multipleResponses;
  final String imageURL;
  String thumbnailURL;

  MultiChoiceQuestion(
    this.postID,
    this.question,
    this.questionDescription,
    this.createdBy,
    this.userDisplayName,
    this.datePosted,
    this.numOfResponses,
    this.questionType,
    this.multipleChoiceAnswers,
    this.topic,
    this.likes,
    this.views,
    this.reports,
    this.anonymous,
    this.multipleResponses,
    this.imageURL,
  );
}

class NumberValueQuestion implements questions {
  final String postID;
  final String question;
  final String questionDescription;
  final String createdBy;
  final String userDisplayName;
  final Timestamp datePosted;
  final int numOfResponses;
  final int questionType;
  final Map likes;
  bool heart = false;
  bool star = false;
  final String topic;
  List<dynamic> views;
  final Map reports;
  final bool anonymous;
  final bool multipleResponses;
  final String imageURL;
  String thumbnailURL;

  NumberValueQuestion(
    this.postID,
    this.question,
    this.questionDescription,
    this.createdBy,
    this.userDisplayName,
    this.datePosted,
    this.numOfResponses,
    this.questionType,
    this.topic,
    this.likes,
    this.views,
    this.reports,
    this.anonymous,
    this.multipleResponses,
    this.imageURL,
  );
}

class Responses {
  final String responseID;
  final String answer;
  final Timestamp datePosted;
  final String createdBy;
  final Map likes;
  String displayName;
  String imageURL;

  Responses(this.responseID, this.answer, this.datePosted, this.createdBy,
      this.displayName, this.likes, this.imageURL);
}

enum questionTypes { SHORT_ANSWER, MULTIPLE_CHOICE, NUMBER_VALUE }

//Stateful widget to build a dynamic post page.
class PostPage extends StatefulWidget {
  questions postInfo;
  String groupOrTopicID;
  String postID;
  String groups_or_topics;

  PostPage(
      this.postInfo, this.groupOrTopicID, this.postID, this.groups_or_topics);

  PostPage.withID(this.postID, this.groups_or_topics, this.groupOrTopicID);

  @override
  _PostPageState createState() => _PostPageState();
}

//State page for PostPage
class _PostPageState extends State<PostPage> {
  GlobalKey key = GlobalKey();

  //Variables
  Future<questions> postInfoFuture;
  Future<QuerySnapshot> responseInfoListFuture;
  Future<List<String>> groupAdvisorIDFuture;
  List<Responses> responseInfoList = [];
  List<String> groupAdvisorIDs = [];

  questions postInfo;
  String groupOrTopicID;
  String postID;
  String groups_or_topics;

  String groupOrTopicCollection;
  String questionCollection;

  bool userResponded = false;

  @override
  void initState() {
    super.initState();
    postInfo = widget.postInfo;
    groupOrTopicID = widget.groupOrTopicID;
    postID = widget.postID;
    groups_or_topics = widget.groups_or_topics;
    postInfoFuture = getPostInfo();
    responseInfoListFuture = getResponses();
    if (groups_or_topics != "topics") {
      groupAdvisorIDFuture = getGroupAdvisorIDs();
    }
  }

  //This function use to update the state for like function
  //Await for firebase execution to finish and the update the state
  Future<void> updateLike(int index, String currentUserId, bool value) async {
    String firstCollection;
    String questionCollection;
    String groupID = groupOrTopicID;

    //determine if a point is being given or taken away
    int pointGivenRemoved = value ? 1 : -1;

    if (groups_or_topics == "topics") {
      firstCollection = "topics";
      questionCollection = "topicQuestions";
    } else {
      firstCollection = "groups";
      questionCollection = "groupQuestions";
    }

    await Firestore.instance
        .collection(firstCollection)
        .document(groupID)
        .collection(questionCollection)
        .document(widget.postID)
        .collection("responses")
        .document(responseInfoList[index].responseID)
        .updateData({'likes.$currentUserId': value});

    //When a response is liked, the user who made the response gains one point
    await Firestore.instance
        .collection('users')
        .document(responseInfoList[index].createdBy)
        .updateData({'earnedPoints': FieldValue.increment(pointGivenRemoved)});

    //Update state after finishing
    setState(() {
      responseInfoList[index].likes[currentUserId] = value;
    });
  }

  //Handle Like:
  handleResponseLike(String currentUserId, int index, BuildContext context) {
    if (CurrentUser.isNotGuest) {
      if (CurrentUser.userID == responseInfoList[index].createdBy) {
        userCantLikeTheirPostMessage(context);
      } else {
        bool _isLiked = responseInfoList[index].likes[currentUserId] == true;
        if (_isLiked) {
          print("Unliked");
          updateLike(index, currentUserId, false);
        } else if (!_isLiked) {
          print("Liked");
          updateLike(index, currentUserId, true);
        }
      }
    } else {
      guestUserSignInMessage(context);
    }
  }

  //Function to get number of likes for each post
  int getLikeCount(Map likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  //Request this post's specific information
  Future<questions> getPostInfo() async {
    questions newPostInfo;
    String collectionType =
        groups_or_topics == "topics" ? "topicQuestions" : "groupQuestions";
    try {
      await Firestore.instance
          .collection(groups_or_topics)
          .document(groupOrTopicID)
          .collection(collectionType)
          .document(postID)
          .get()
          .then((DocumentSnapshot doc) {
        //Give specific class type based on question type
        switch (questionTypes.values[doc["questionType"] as int]) {
          case questionTypes.SHORT_ANSWER:
            {
              newPostInfo = new basicQuestionInfo(
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
              );
              break;
            }
          case questionTypes.MULTIPLE_CHOICE:
            {
              newPostInfo = new MultiChoiceQuestion(
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
              );
              break;
            }
          case questionTypes.NUMBER_VALUE:
            {
              newPostInfo = new NumberValueQuestion(
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
              );
              break;
            }
        }
      });
    } catch (e) {
      return null;
    }
    return newPostInfo;
  }

  //Request this posts responses as a stream
  Stream getResponseInfoStream() {
    String firstCollection;
    String questionCollection;
    String groupID = groupOrTopicID;

    if (groups_or_topics == "topics") {
      firstCollection = "topics";
      questionCollection = "topicQuestions";
      //groupID = widget.groupOrTopicID.toLowerCase(); //Topic should be lowercase
    } else {
      firstCollection = "groups";
      questionCollection = "groupQuestions";
    }

    return Firestore.instance
        .collection(firstCollection)
        .document(groupID)
        .collection(questionCollection)
        .document(widget.postID)
        .collection("responses")
        .snapshots();
  }

  List<Responses> populateList(AsyncSnapshot query) {
    List<Responses> infoList = [];

    query.data.documents.forEach((doc) {
      infoList.add(new Responses(
          doc.documentID,
          doc.data["answer"].toString(),
          doc.data["datePosted"],
          doc.data["createdBy"],
          doc.data["userDisplayName"],
          doc.data["likes"],
          doc.data["imageURL"]));
    });

    return infoList;
  }

  //Check if a user has already responded to this question
  bool hasUserResponded(AsyncSnapshot query) {
    for (DocumentSnapshot doc in query.data.documents) {
      if (doc["createdBy"] == CurrentUser.userID) {
        return true;
      }
    }
    return false;
  }

  Future<List<String>> getGroupAdvisorIDs() async {
    List<String> advisorIDs = [];
    await Firestore.instance
        .collection("groups")
        .document(groupOrTopicID)
        .get()
        .then((DocumentSnapshot doc) {
      if (doc["advisors"] == null) {
        advisorIDs = new List();
      } else {
        advisorIDs = new List<String>.from(doc["advisors"]);
      }
    });
    setState(() {
      groupAdvisorIDs = advisorIDs;
    });

    return advisorIDs;
  }

  Widget addImage() {
    if (postInfo.imageURL == null)
      return Container();
    else {
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FullPhoto(url: postInfo.imageURL)));
//
        },
        child: Hero(
          tag: "image",
          child: Container(
              child: Padding(
            padding: EdgeInsets.only(top: 10, right: 15),
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(postInfo.imageURL),
              radius: 50,
            ),
          )),
        ),
      );
    }
  }

  Widget buildCard(String questionTitle, String questionDescription,
      String uDisplayName, String createdBy, bool isAnonymous) {
    Size screenSize = MediaQuery.of(context).size;
    return Card(
        child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: ListTile(
                title: Text(
                  questionTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                subtitle: Text(
                  questionDescription,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            addImage(),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 17),
          width: screenSize.width,
          child: GestureDetector(
              child: InkWell(
                child: AutoSizeText(
                  isAnonymous
                      ? "Posted by Anonymous " +
                          timeago.format(postInfo.datePosted.toDate())
                      : "Posted by " +
                          uDisplayName +
                          " " +
                          timeago.format(postInfo.datePosted.toDate()),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              onTap: () {
                if (isAnonymous) {
                  Flushbar(
                    message:
                        "This user is anonymous, you can not view their page.",
                    duration: Duration(seconds: 5),
                    backgroundColor: Colors.teal,
                  )..show(context);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return new profile.UserDetailsPage(createdBy);
                    }),
                  );
                }
              }),
        ),
      ],
    ));
  }

  //Display the advisor tag if that user is an advisor
  Widget displayAdvisorTag(
      Size screenSize, String uDisplayName, String createdBy, var datePosted) {
    if (uDisplayName.length > 20) {
      uDisplayName = uDisplayName.split(" ")[0];
    }
    if (groupAdvisorIDs.contains(createdBy)) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
        child: GestureDetector(
          child: Container(
            //width: 20,
            //changed to from 100 - 35
            width: screenSize.width - 80,
            //Set the name for every card
            child: Column(
              children: <Widget>[
                Container(
                  width: screenSize.width - 105,
                  child: AutoSizeText(
                    "Posted by " +
                        uDisplayName +
                        " \u2713 " +
                        timeago.format(datePosted.toDate()),
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return new profile.UserDetailsPage(createdBy);
            }),
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
        child: GestureDetector(
          child: Container(
            //width: 20,
            //changed to from 100 - 35
            width: screenSize.width - 80,
            //Set the name for every card
            child: Column(
              children: <Widget>[
                Container(
                  width: screenSize.width - 105,
                  child: AutoSizeText(
                    "Posted by " +
                        uDisplayName +
                        " " +
                        timeago.format(datePosted.toDate()),
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return new profile.UserDetailsPage(createdBy);
            }),
          ),
        ),
      );
    }
  }

  Future<QuerySnapshot> getResponses() async {
    if (groups_or_topics == "topics") {
      groupOrTopicCollection = "topics";
      questionCollection = "topicQuestions";
      //groupID = widget.groupOrTopicID.toLowerCase(); //Topic should be lowercase
    } else {
      groupOrTopicCollection = "groups";
      questionCollection = "groupQuestions";
    }

    return await Firestore.instance
        .collection(groupOrTopicCollection)
        .document(groupOrTopicID)
        .collection(questionCollection)
        .document(widget.postID)
        .collection("responses")
        .getDocuments();
  }

  Future<void> addViewToDatabase() async {
    //Create new list since postInfo is a fixed-length list.
    List<dynamic> newIDList = new List.from(postInfo.views);
    await Firestore.instance
        .collection(groupOrTopicCollection)
        .document(groupOrTopicID)
        .collection(questionCollection)
        .document(widget.postID)
        .updateData({
      "views": FieldValue.arrayUnion([CurrentUser.userID])
    });
    newIDList.add(CurrentUser.userID);
    setState(() {
      postInfo.views = new List.from(newIDList);
    });
  }

  @override
  Widget build(BuildContext context) {
    String questionCollection;
    String firstCollection;
    if (widget.groups_or_topics == "topics") {
      questionCollection = "topicQuestions";
      firstCollection = "topics";
      //groupOrTopicID = groupOrTopicID.toLowerCase(); //Topic document is lowercase
    } else {
      questionCollection = "groupQuestions";
      firstCollection = "groups";
    }

    return FutureBuilder(
      future: groups_or_topics != "topics"
          ? Future.wait([
              postInfoFuture,
              groupAdvisorIDFuture,
            ])
          : Future.wait([postInfoFuture]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (postInfo == null) {
            postInfo = snapshot.data[0];
            if (postInfo == null) {
              return Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  automaticallyImplyLeading: true,
                  title: Text("No Post"),
                ),
                body: Stack(
                  children: <Widget>[
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "Post no longer exists, sorry!",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                postQuestion(null, null) //AddPost(),
                            ));
                  },
                  heroTag: "questionPageHero",
                  tooltip: 'Increment',
                  child: CircleAvatar(
                    child: Image.asset(
                      'images/addPostIcon4.png',
                    ),
                    maxRadius: 18,
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar:
                    globalNavigationBar(3, context, key, false),
              );
            }
          }
          return StreamBuilder(
            stream: getResponseInfoStream(),
            builder: (context, responsesSnapshot) {
              if (responsesSnapshot.hasData) {
                if (postInfo.views != null) {
                  if (!postInfo.views.contains(CurrentUser.userID))
                    addViewToDatabase();
                } else
                  addViewToDatabase();
                var questionObj = postInfo;
                responseInfoList = populateList(responsesSnapshot);
                userResponded = hasUserResponded(responsesSnapshot);
                if (questionObj is basicQuestionInfo) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                      title: Text("View Post"),
                      centerTitle: true,
                    ),
                    floatingActionButton: FloatingActionButton(
                      heroTag: "qpHero2",
                      backgroundColor:
                          (userResponded && !postInfo.multipleResponses) ||
                                  CurrentUser.userID == questionObj.createdBy
                              ? Colors.grey
                              : Colors.teal,
                      child: Icon(Icons.comment),
                      onPressed: () {
                        if (CurrentUser.isNotGuest) {
                          if (CurrentUser.userID == questionObj.createdBy) {
                            userCantPostOnTheirQuestionMessage(context);
                          } else if (!userResponded ||
                              postInfo.multipleResponses) {
                            setState(() {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return new postResponse(
                                    questionObj.postID,
                                    groupOrTopicID,
                                    questionTypes
                                        .values[questionObj.questionType],
                                    groups_or_topics,
                                    questionObj);
                              }));
                            });
                          } else {
                            userAlreadyRespondedMessage(context);
                          }
                        } else {
                          guestUserSignInMessage(context);
                        }
                      },
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: globalNavigationBar(
                        groups_or_topics == "topics" ? 0 : 1,
                        context,
                        key,
                        false),
                    body: Stack(
                      children: <Widget>[
                        SafeArea(
                          child: Column(
                            children: <Widget>[
                              buildCard(
                                questionObj.question,
                                questionObj.questionDescription,
                                questionObj.userDisplayName,
                                questionObj.createdBy,
                                questionObj.anonymous,
                              ),
                              generateResponseCards(groupOrTopicID),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  //If the question is multiple choice, route the user to the correct type of page.
                } else if (questionObj is MultiChoiceQuestion) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                      title: Text("View Post"),
                      centerTitle: true,
                    ),
                    floatingActionButton: FloatingActionButton(
                      heroTag: "qpHeroo",
                      backgroundColor:
                          (userResponded && !questionObj.multipleResponses) ||
                                  CurrentUser.userID == questionObj.createdBy
                              ? Colors.grey
                              : Colors.teal,
                      child: Icon(Icons.comment),
                      onPressed: () {
                        if (CurrentUser.isNotGuest) {
                          if (CurrentUser.userID == questionObj.createdBy) {
                            userCantPostOnTheirQuestionMessage(context);
                          } else if (!userResponded ||
                              postInfo.multipleResponses) {
                            setState(() {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return new postResponse.withChoices(
                                    questionObj.postID,
                                    groupOrTopicID,
                                    questionTypes
                                        .values[questionObj.questionType],
                                    questionObj.multipleChoiceAnswers,
                                    groups_or_topics,
                                    questionObj);
                              }));
                            });
                          } else {
                            userAlreadyRespondedMessage(context);
                          }
                        } else {
                          guestUserSignInMessage(context);
                        }
                      },
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: globalNavigationBar(
                        groups_or_topics == "topics" ? 0 : 1,
                        context,
                        key,
                        false),
                    body: Stack(
                      children: <Widget>[
                        SafeArea(
                          child: Column(
                            children: <Widget>[
                              buildCard(
                                questionObj.question,
                                questionObj.questionDescription,
                                questionObj.userDisplayName,
                                questionObj.createdBy,
                                questionObj.anonymous,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 3,
                                  top: 5,
                                  bottom: 5,
                                  right: 5,
                                ),
                                child: Center(
                                  child: postChartButton(
                                      groups_or_topics == "groups"
                                          ? groupOrTopicID
                                          : groupOrTopicID, //.toLowerCase(),
                                      questionObj.postID,
                                      "pie",
                                      context,
                                      groups_or_topics,
                                      questionObj.numOfResponses),
                                ),
                              ),
                              generateResponseCards(groupOrTopicID),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (questionObj is NumberValueQuestion) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                      title: Text("View Post"),
                      centerTitle: true,
                    ),
                    floatingActionButton: FloatingActionButton(
                      heroTag: "qpHeroa1",
                      backgroundColor:
                          (userResponded && !postInfo.multipleResponses) ||
                                  CurrentUser.userID == questionObj.createdBy
                              ? Colors.grey
                              : Colors.teal,
                      child: Icon(Icons.comment),
                      onPressed: () {
                        if (CurrentUser.isNotGuest) {
                          if (CurrentUser.userID == questionObj.createdBy) {
                            userCantPostOnTheirQuestionMessage(context);
                          } else if (!userResponded ||
                              postInfo.multipleResponses) {
                            setState(() {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return new postResponse(
                                    questionObj.postID,
                                    groupOrTopicID,
                                    questionTypes
                                        .values[questionObj.questionType],
                                    groups_or_topics,
                                    questionObj);
                              }));
                            });
                          } else {
                            userAlreadyRespondedMessage(context);
                          }
                        } else {
                          guestUserSignInMessage(context);
                        }
                      },
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: globalNavigationBar(
                        groups_or_topics == "topics" ? 0 : 1,
                        context,
                        key,
                        false),
                    body: Stack(
                      children: <Widget>[
                        SafeArea(
                          child: Column(
                            children: <Widget>[
                              buildCard(
                                questionObj.question,
                                questionObj.questionDescription,
                                questionObj.userDisplayName,
                                questionObj.createdBy,
                                questionObj.anonymous,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 3,
                                  top: 5,
                                  bottom: 5,
                                  right: 5,
                                ),
                                child: Center(
                                  child: postChartButton(
                                      groups_or_topics == "groups"
                                          ? groupOrTopicID
                                          : groupOrTopicID, //.toLowerCase(),
                                      questionObj.postID,
                                      "number",
                                      context,
                                      groups_or_topics,
                                      questionObj.numOfResponses),
                                ),
                              ),
                              generateResponseCards(groupOrTopicID),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container();
                }
              }
              return Scaffold(
                  floatingActionButton: FloatingActionButton(
                    heroTag: "qqpheroo2",
                    child: Icon(Icons.comment),
                    onPressed: () {},
                  ),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(
                      groups_or_topics == "topics" ? 0 : 1,
                      context,
                      key,
                      false),
                  body: Center(child: CircularProgressIndicator()));
            },
          );
        } else {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              heroTag: "qpheroo3",
              child: Icon(Icons.comment),
              onPressed: () {},
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: globalNavigationBar(
                groups_or_topics == "topics" ? 0 : 1, context, key, false),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  //Display responses
  Widget generateResponseCards(String groupID) {
    Size screenSize = MediaQuery.of(context).size;
    return Expanded(
      child: SizedBox(
        //height: 500.0,
        child: ListView.builder(
          itemCount: responseInfoList.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            print("the answer for basic question");
            print(responseInfoList[index].answer);
            return Column(
              children: <Widget>[
                //_buildIconTile(responseInfoList[index].answer)
                Divider(),
                ListTile(
                  key: Key(responseInfoList[index].responseID),
                  title: Text(
                    responseInfoList[index].answer,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: displayAdvisorTag(
                      screenSize,
                      responseInfoList[index].displayName,
                      responseInfoList[index].createdBy,
                      responseInfoList[index].datePosted),
                  trailing: GestureDetector(
                    onTap: () => handleResponseLike(
                      CurrentUser.userID,
                      index,
                      context,
                    ),
                    child: CurrentUser.isNotGuest &&
                            getLikeCount(responseInfoList[index].likes) != 0
                        ? new Stack(
                            children: <Widget>[
                              Container(
                                  width: 57,
                                  height: 31,
                                  child: new Icon(
                                    responseInfoList[index]
                                                .likes[CurrentUser.userID] ==
                                            true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 25,
                                    color: Colors.teal, //Color(0xFFB83330),
                                  )),
                              getLikeCount(responseInfoList[index].likes) != 0
                                  ? new Positioned(
                                      left: 35,
                                      bottom: 15,
                                      child: new Container(
                                        padding: EdgeInsets.only(
                                            left: 1.0, right: 1.0),
                                        constraints: BoxConstraints(
                                          minWidth: 14,
                                          minHeight: 14,
                                        ),
                                        child: AutoSizeText(
                                          "${getLikeCount(responseInfoList[index].likes)}",
                                          style: TextStyle(
                                            color: Colors
                                                .teal, //Color(0xFFB83330),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : new Container()
                            ],
                          )
                        : Container(
                            width: 57,
                            height: 31,
                            child: Icon(
                              Icons.favorite_border,
                              size: 25,
                              color: Colors.teal,
                              // Color(0xFFB83330),
                            ),
                          ),
                  ),
                ),
                responseInfoList[index].imageURL == null
                    ? Container()
                    : GestureDetector(
                        child: showNewImage(responseInfoList[index].imageURL),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FullPhoto(
                                      url: responseInfoList[index].imageURL)));
                        },
                      ),
                Divider(),
                index == responseInfoList.length - 1
                    ? SizedBox(height: 40)
                    : Container(),
              ],
            );
          },
        ),
      ),
    );
  } //End of Responses

  Widget showNewImage(String image) {
    if (image == null) {
      return Container();
    } else {
      return SizedBox(
        child: Image.network(image),
        width: 250.0,
        height: 250.0,
      );
    }
  }

  Widget userAlreadyRespondedMessage(BuildContext context) {
    return Flushbar(
      title: "You have already responded!",
      message: "You have already submitted a response to this question!",
      duration: Duration(seconds: 6),
      backgroundColor: Colors.teal,
    )..show(context);
  }

  Widget userCantPostOnTheirQuestionMessage(BuildContext context) {
    return Flushbar(
      title: "This is your post!",
      message: "Sorry, you can't reply to your own post!",
      duration: Duration(seconds: 6),
      backgroundColor: Colors.teal,
    )..show(context);
  }
}

class postQuestion extends StatefulWidget {
  String groupOrTopicID;
  User userPosting;

  postQuestion(this.groupOrTopicID, this.userPosting);

  @override
  _PostQuestionState createState() => _PostQuestionState();
}

class _PostQuestionState extends State<postQuestion> {
  //Variables
  GlobalKey key = GlobalKey();
  String currentGroupID;
  var questionType = questionTypes.SHORT_ANSWER;
  List<MultipleChoiceEntry> multiChoiceList = [];
  List<User> advisorsList = [];
  List<String> advisorIDs = [];
  int currentTab = 1;
  var databaseInstance = Firestore.instance.collection('groups');
  User userInfo;
  String selectedTopic;
  List<String> topicList = new List();
  final ScrollController scrollController = new ScrollController();
  final questionController = TextEditingController();
  final questionDescriptionController = TextEditingController();
  bool postAnonymously = false;
  bool multipleResponses = false;

  var _formKey = GlobalKey<FormState>();

  List<TextEditingController> responseControllers = [];

  File _image;
  String imageURL;

  @override
  void initState() {
    super.initState();
    if (widget.groupOrTopicID != null) {
      currentGroupID = widget.groupOrTopicID;
      userInfo = widget.userPosting;
      getAdvisors().then((onValue) => advisorsList = onValue);
    } else {
      getTopics();
    }
  }

  Future<void> getTopics() async {
    List<String> tempTopics = new List();
    tempTopics.add("All");

    await Firestore.instance
        .collection('topics')
        .orderBy('topicName', descending: false)
        .getDocuments()
        .then((QuerySnapshot data) =>
            data.documents.forEach((doc) => tempTopics.add(
                  doc["topicName"],
                )));

    setState(() {
      topicList = tempTopics;
    });
  }

  Future<List<User>> getAdvisors() async {
    List<User> advisors = [];
    await databaseInstance
        .document(currentGroupID)
        .get()
        .then((DocumentSnapshot doc) {
      List<dynamic> advisorIDs = doc["advisors"];
      for (var advisorID in advisorIDs) {
        getUserInformation(advisorID)
            .then((userInfo) => advisors.add(userInfo));
      }
    });
    return advisors;
  }

  Future<void> sendAdvisorNotification(String postID) async {
    final activityFeedRef = Firestore.instance.collection('Notification');

    for (String advisor in advisorIDs) {
      User advisorInfo =
          advisorsList.firstWhere((user) => user.userID == advisor);
      await activityFeedRef
          .document(advisor)
          .collection("NotificationItems")
          .document()
          .setData({
        "type": "advisorHelp",
        "postID": postID,
        "profileImg": userInfo.profilePicURL,
        "requestor": userInfo.displayName,
        "timestamp": Timestamp.now(),
        "groups_or_topics": "groups",
        "groupOrTopicID": currentGroupID,
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Colors.teal,
        title: Text("Post Question"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "qpqpqphero1",
        tooltip: 'Increment',
        child: Icon(Icons.check),
        onPressed: () {
          if (widget.groupOrTopicID == null) {
            //Validation for topic selecting
            if (selectedTopic == null) {
              selectTopicValidation();
            } else if (_formKey.currentState.validate()) {
              //This statement is for dashboard posts
              //Insert post logic here
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteDashboardAdvisors(
                        selectedTopic,
                        postAnonymously,
                        questionType,
                        multiChoiceList,
                        questionController.text.toString(),
                        questionDescriptionController.text.toString(),
                        responseControllers,
                        _image,
                        multipleResponses),
                  ));
            }
          } else if (_formKey.currentState
                  .validate() && //This statement is for group posts
              widget.groupOrTopicID != null) {
            _formKey.currentState.save();

            setState(() {
              inviteAdvisors();
            });
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(
          widget.groupOrTopicID == null ? 0 : 1, context, key, false),
      body: Container(
        child: ListView(
          children: <Widget>[
            buildQuestionType(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                    )
                  ],
                ),
              ],
            ),
            //Build drop down for topic
            widget.groupOrTopicID == null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: buildDropdownTopicSelect(topicList),
                  )
                : Container(),
            //Build dropdown for type of question
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: buildDropdownQuestionSelect(),
            ),
            //Build post anonymously checkbox
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2),
              child: CheckboxListTile(
                title: const Text("Post anonymously?"),
                value: postAnonymously,
                onChanged: (bool value) {
                  setState(() {
                    postAnonymously = value;
                  });
                },
                secondary: Icon(Icons.remove_red_eye),
              ),
            ),
            //Build post anonymously checkbox
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2),
              child: CheckboxListTile(
                title: const Text("Allow multiple responses?"),
                value: multipleResponses,
                onChanged: (bool value) {
                  setState(() {
                    multipleResponses = value;
                  });
                },
                secondary: Icon(Icons.group),
              ),
            ),
            showImageThumbnail(),
            buildAttachImageButton(),
          ],
        ),
      ),
    );
  }

  //Return the image thumbnail if the image exists
  Widget showImageThumbnail() {
    //If the image is null, do nothing and skip to return container()
    if (ImageNullorExist()) {
      return Image.file(_image);
    }
    return Container();
  }

  //Checks if the image is null or if it exists.
  bool ImageNullorExist() {
    if (_image == null) {
    } else {
      if (_image.existsSync()) {
        return true;
      }
    }
    return false;
  }

  Widget buildDropdownTopicSelect(List<String> topics) {
    if (topics != null && topics.contains("All")) {
      topics.remove("All");
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Icon(Icons.list),
        Center(
          child: DropdownButton<String>(
            hint: new Text("Select a topic               ",
                style: TextStyle(color: Colors.black)),
            value: selectedTopic,
            items: topics.map((String tempValue) {
              return new DropdownMenuItem<String>(
                value: tempValue,
                child: new Text(tempValue),
              );
            }).toList(),
            onChanged: (String tempValue) {
              setState(() {
                selectedTopic = tempValue;
                print(selectedTopic);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildDropdownQuestionSelect() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
        Icon(Icons.list),
      Center(
      child: DropdownButton<questionTypes>(
        hint: new Text("Select a question type"),
        value: questionType,
        onChanged: (questionTypes newType) {
          setState(() {
            questionType = newType;
          });
        },
        items: [
          DropdownMenuItem<questionTypes>(
            value: questionTypes.SHORT_ANSWER,
            child: Text("Short Answer"),
          ),
          DropdownMenuItem<questionTypes>(
            value: questionTypes.MULTIPLE_CHOICE,
            child: Text("Multiple Choice"),
          ),
          DropdownMenuItem<questionTypes>(
            value: questionTypes.NUMBER_VALUE,
            child: Text("Number"),
          ),
        ],
      ),
    ),
    ]
    );
  }

  Future selectTopicValidation() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(
                "Please select a topic!",
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                GestureDetector(
                  child: Text(
                    "Ok",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ])));
        });
  }

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
        "profileImg": CurrentUser.profilePicURL,
        "requestor": CurrentUser.displayName,
        "timestamp": Timestamp.now(),
        "groups_or_topics": "topics",
        "groupOrTopicID": selectedTopic,
      });
    }
    //Navigator.pop(context);
  }

  //Widget that will attach an image
  Widget buildAttachImageButton() {
    return Padding(
      padding: EdgeInsets.only(left: 10, top: 8, bottom: 30),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                getImageMenu();
              },
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                  color: Color(0xFF009688),
                ),
                child: Center(
                  child: Text(
                    "Attach Image",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.0),
        ],
      ),
    );
  }

  //Brings up small dialog for inviting advisors to answer questions within a group
  Future<void> inviteAdvisors() async {
    //Start by checking if the user posting is an advisor for the group and removing them
    advisorsList.removeWhere((user) => user.userID == CurrentUser.userID);

    if (advisorsList.isEmpty) {
      uploadQuestionToDatabase(false);
      Navigator.pop(context);
    } else {
      return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              contentPadding: EdgeInsets.only(top: 10.0),
              content: Container(
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "Invite Advisors",
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Divider(
                      color: Color(0xFFCBD7D0),
                      height: 4.0,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 30.0, right: 30.0),
                      child: Container(
                        height: 125.0,
                        child: SingleChildScrollView(
                          child: MultiSelectChipUser(advisorsList, advisorIDs,
                              onSelectionChanged: (selectedList) {
                            setState(() {
                              advisorIDs = selectedList;
                            });
                          }),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            uploadQuestionToDatabase(true);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 138.0,
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32.0),
                              ),
                            ),
                            child: Text(
                              "Send",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 3.0,
                        ),
                        InkWell(
                          onTap: () {
                            uploadQuestionToDatabase(false);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 138.0,
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.only(
                                  // bottomLeft: Radius.circular(32.0),
                                  bottomRight: Radius.circular(32.0)),
                            ),
                            child: Text(
                              "Not Now",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
    }
  }

  //Gets question type and calls appropriate functions for that type
  Widget buildQuestionType() {
    switch (questionType) {
      //Standard form question
      case questionTypes.SHORT_ANSWER:
        {
          return Form(
            key: _formKey,
            child: createGenericPostQuestion(),
          );
        }
      //Multiple choice
      case questionTypes.MULTIPLE_CHOICE:
        {
          return Form(
            key: _formKey,
            child: Container(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: new TextFormField(
                      maxLines: 2,
                      controller: questionController,
                      decoration: new InputDecoration(labelText: 'Question'),
                      //autovalidate: true,
                      validator: (value) {
                        if (value.isEmpty) return "Please enter a question";
                        return null;
                      },
                      maxLength: 100,
                      onSaved: (value) => questionController.text = value,
                    ),
                  ),
                  new SizedBox(
                    height: 15.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: new TextFormField(
                      controller: questionDescriptionController,
                      maxLines: 6,
                      decoration: new InputDecoration(labelText: 'Description'),
                      //autovalidate: true,
                      maxLength: 250,
                      validator: (value) {
                        if (value.isEmpty) return "Please enter a description";
                        return null;
                      },
                      onSaved: (value) =>
                          questionDescriptionController.text = value,
                    ),
                  ),
                  createMultipleChoiceOption(),
                ],
              ),
            ),
          );
        }
      //Number answer
      case questionTypes.NUMBER_VALUE:
        {
          return Form(
            key: _formKey,
            child: createNumberPostQuestion(),
          );
        }
    }
  }

  //Generates the question posts for number value type questions
  Container createNumberPostQuestion() {
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: new TextFormField(
              controller: questionController,
              maxLines: 3,
              decoration: new InputDecoration(labelText: 'Question'),
              //autovalidate: true,
              maxLength: 100,
              validator: (value) {
                if (value.isEmpty) return "Please enter a question";
                return null;
              },
              onSaved: (value) => questionController.text = value,
            ),
          ),
          new SizedBox(
            height: 15.0,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: new TextFormField(
              controller: questionDescriptionController,
              maxLines: 6,
              decoration: new InputDecoration(labelText: 'Description'),
              //autovalidate: true,
              maxLength: 250,
              validator: (value) {
                if (value.isEmpty) return "Please enter a description";
                return null;
              },
              onSaved: (value) => questionDescriptionController.text = value,
            ),
          ),
        ],
      ),
    );
  }

  //Generates the page for short answer questions
  Container createGenericPostQuestion() {
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: new TextFormField(
              controller: questionController,
              maxLines: 3,
              decoration: new InputDecoration(labelText: 'Question'),
              //autovalidate: true,
              maxLength: 100,
              validator: (value) {
                if (value.isEmpty) return "Please enter a question";
                return null;
              },
              onSaved: (value) => questionController.text = value,
            ),
          ),
          new SizedBox(
            height: 15.0,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: new TextFormField(
              controller: questionDescriptionController,
              maxLines: 6,
              decoration: new InputDecoration(labelText: 'Description'),
              //autovalidate: true,
              maxLength: 250,
              validator: (value) {
                if (value.isEmpty) return "Please enter a description";
                return null;
              },
              onSaved: (value) => questionDescriptionController.text = value,
            ),
          ),
        ],
      ),
    );
  }

  //Builds list of multiple choice options
  Widget createMultipleChoiceOption() {
    if (multiChoiceList.length == 0) {
      for (int i = 0; i < 2; i++) {
        responseControllers.add(new TextEditingController());
        multiChoiceList.add(MultipleChoiceEntry());
      }
    }

    //Expanded allows column to fill entire screen
    return Column(
      children: <Widget>[
        ColumnBuilder(
          itemCount: multiChoiceList.length,
          itemBuilder: (context, index) {
            final entry = multiChoiceList[index];
            return Dismissible(
                key: Key(multiChoiceList[index].key.toString()),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                  setState(() {
                    responseControllers.removeAt(index);
                    multiChoiceList.removeAt(index);
                  });
                },
                child:
                    entry.buildMultipleChoiceEntry(responseControllers[index]));
          },
        ),
        Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 10),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //Check if we need add or remove buttons
                determineAddButton(),
              ],
            )),
      ],
    );
  }

  //Function that returns a FAB if multiple choice number does not exceed 5, blank otherwise
  Widget determineAddButton() {
    if (multiChoiceList.length != 5) {
      //Build padding for other FAB if also present
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {});
            //increment choices counter for rebuild of choice list
            responseControllers.add(new TextEditingController());
            multiChoiceList.add(MultipleChoiceEntry());
          },
          child: Container(
            height: 40.0,
            decoration: BoxDecoration(
              borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
              color: Color(0xFF009688),
            ),
            child: Center(
              child: Text(
                "Add Option",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
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

    if (_image.existsSync()) {
      imageUpdatedMessage(context);
    } else {
      imageFailedToUpdateMessage(context);
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

    if (_image.existsSync()) {
      imageUpdatedMessage(context);
    } else {
      imageFailedToUpdateMessage(context);
    }
  }

  Widget showNewImage(String image) {
    if (image == null) {
      return Container();
    } else {
      return SizedBox(
        child: Image.network(image),
        width: 250.0,
        height: 250.0,
      );
    }
  }

  /*Button action calls this function, this function displays the options
  the user has, they can choose Camera or Gallery*/
  Future getImageMenu() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Snap or Choose a Photo?"),
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

  Future<void> uploadImageToDatabase(String documentID) async {
    if (ImageNullorExist()) {
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("postPictures/" + documentID + "postPicture");
      final StorageUploadTask uploadTask = pictureNameInStorage.putFile(_image);
      await uploadTask.onComplete;

      imageURL = await pictureNameInStorage.getDownloadURL() as String;
    }
  }

  //Uploads the question the database for groups only
  Future<void> uploadQuestionToDatabase(bool needAdvisors) async {
    bool noPoints = false;
    DocumentReference newPost = databaseInstance
        .document(currentGroupID)
        .collection("groupQuestions")
        .document();
    DocumentReference currentUser =
        Firestore.instance.collection('users').document(userInfo.userID);

    String postDisplayName;

    //Bool to flag if a user is out of points
    bool outOfPoints = false;

    //If posting anonymously, label postDisplayName as "anonymous"
    if (postAnonymously) {
      postDisplayName = "Anonymous";
    } else {
      //Otherwise, postDisplayName is the user's display name
      postDisplayName = CurrentUser.displayName;
    }

    await Firestore.instance
        .collection('users')
        .document(userInfo.userID)
        .get()
        .then((DocumentSnapshot doc) {
      int earnedPoints = doc["earnedPoints"];
      int dailyPoints = doc["dailyPoints"];

      if (dailyPoints >= 10) {
        currentUser.updateData({
          'myPosts': FieldValue.arrayUnion([newPost]),
          'dailyPoints': FieldValue.increment(-10),
        });
      } else if (earnedPoints >= 10) {
        currentUser.updateData({
          'myPosts': FieldValue.arrayUnion([newPost]),
          'earnedPoints': FieldValue.increment(-10),
        });
      } else {
        //Set flag for database upload
        outOfPoints = true;
        Flushbar(
          title: "No Points!",
          message:
              "Sorry you're out of points, please answer more questions or come"
              "back tomorrow.",
          duration: Duration(seconds: 5),
          backgroundColor: Colors.teal,
        )..show(context);
      }
    });

    if (noPoints) {
      return null;
    }

    //If advisors were requested, send them a notification here
    if (needAdvisors == true) {
      sendAdvisorNotification(newPost.documentID);
    }

    //If the user is out of points, do not post the question
    if (!outOfPoints) {
      //Start by uploading the image to the database, if there is one.
      await uploadImageToDatabase(newPost.documentID);

      switch (questionType) {
        case questionTypes.SHORT_ANSWER:
          {
            return newPost.setData({
              'question': questionController.text.toString(),
              'description': questionDescriptionController.text.toString(),
              'createdBy': userInfo.userID.toString(),
              'userDisplayName': postDisplayName,
              'dateCreated': Timestamp.now(),
              'numOfResponses': 0,
              'likes': {},
              'questionType': questionTypes.SHORT_ANSWER.index,
              'views': new List(),
              'reports': {},
              'imageURL': imageURL,
              'multipleResponses': multipleResponses,
              'anonymous': postAnonymously,
            });
          }
        case questionTypes.MULTIPLE_CHOICE:
          {
            List<String> choices = [];

            for (int i = 0; i < multiChoiceList.length; i++) {
              choices.add(responseControllers[i].text);
            }

            return newPost.setData({
              'question': questionController.text.toString(),
              'description': questionDescriptionController.text,
              'choices': choices,
              'createdBy': userInfo.userID.toString(),
              'userDisplayName': postDisplayName,
              'dateCreated': Timestamp.now(),
              'numOfResponses': 0,
              'likes': {},
              'questionType': questionTypes.MULTIPLE_CHOICE.index,
              'views': new List(),
              'reports': {},
              'imageURL': imageURL,
              'multipleResponses': multipleResponses,
              'anonymous': postAnonymously,
            });
          }
        case questionTypes.NUMBER_VALUE:
          {
            return newPost.setData({
              'question': questionController.text.toString(),
              'description': questionDescriptionController.text.toString(),
              'createdBy': userInfo.userID.toString(),
              'userDisplayName': postDisplayName,
              'dateCreated': Timestamp.now(),
              'numOfResponses': 0,
              'likes': {},
              'questionType': questionTypes.NUMBER_VALUE.index,
              'views': new List(),
              'reports': {},
              'imageURL': imageURL,
              'multipleResponses': multipleResponses,
              'anonymous': postAnonymously,
            });
          }
      }
      Navigator.pop(context);
    }
  }
}

class ColumnBuilder extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection textDirection;
  final VerticalDirection verticalDirection;
  final int itemCount;

  const ColumnBuilder({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.mainAxisAlignment: MainAxisAlignment.start,
    this.mainAxisSize: MainAxisSize.max,
    this.crossAxisAlignment: CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection: VerticalDirection.down,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: new List.generate(
          this.itemCount, (index) => this.itemBuilder(context, index)).toList(),
    );
  }
}
