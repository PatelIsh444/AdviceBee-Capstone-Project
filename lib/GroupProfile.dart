import './utils/GroupInformation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GroupSettings.dart';
import 'QuestionPage.dart';
import 'MoreMenu.dart';
import 'QuestionCards.dart';
import 'User.dart';
import './utils/commonFunctions.dart';
import 'Dashboard.dart';



class GroupProfile extends StatefulWidget {
  GroupInformation groupInfo;
  String groupID;

  GroupProfile(this.groupInfo);

  //Used for pages that do not pass the group info, such as searching
  GroupProfile.withID(this.groupID);

  @override
  _GroupProfileState createState() => _GroupProfileState();
}

//Group Profile will hold other information about groups such as members, questions, etc. currently a WIP
class _GroupProfileState extends State<GroupProfile> {
  List<questions> postInfoList = [];
  int numOfPosts = 0;
  var _userCreated = false;
  GroupInformation groupInfo;
  List<SortValues> choices = <SortValues>[
    SortValues("Sort Posts By:", false),
    SortValues("Recently Added", true),
    SortValues("Most Likes", false),
    SortValues("Most Viewed", false),
    SortValues("Most Responded", false),
  ];
  String currentChoice = "recently added";
  Future<GroupInformation> getGroupInformationFuture;

  Future<List<questions>> getGroupPostInfoFuture;

  int currentTab = 1;
  GlobalKey key = GlobalKey();


  @override
  void initState() {
    super.initState();
    if (widget.groupInfo != null)
      groupInfo = widget.groupInfo;

    getGroupInformationFuture = getGroupInformation();
  }

  Future<GroupInformation> getGroupInformation() async {
    GroupInformation internalGroupInfo;
    if(groupInfo == null) {
      await Firestore.instance
          .collection("groups")
          .document(widget.groupID)
          .get()
          .then((DocumentSnapshot doc) {
        internalGroupInfo = new GroupInformation(
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
    }
    else{
      internalGroupInfo = groupInfo;
    }
    return internalGroupInfo;
  }

  Future<User> createUser() async {
    if (!_userCreated) {
      // 1) check if user exists in users collection in database (according to their id)
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      if (!user.isAnonymous && CurrentUser == null) {
        DocumentSnapshot doc = await Firestore.instance
            .collection('users')
            .document(user.uid)
            .get();
        CurrentUser = User.fromDocument(doc);
        return CurrentUser;
      }
      //if guest then set isGuest as false
      else {
        user.isAnonymous
            ? CurrentUser.isNotGuest = false
            : CurrentUser.isNotGuest = false;
      }

      setState(() {
        _userCreated = true;
      });
    }
  }

  //Holds information for group profile
  Widget buildProfileImage() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.5, 0.9],
              colors: [
                Color(0xFFFCB43A),
                Color(0xFFFCD615)
              ]
          )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 40,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              CircleAvatar(
                minRadius: 60,
                backgroundColor: Color(0xFFFCB43A),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(groupInfo.imageURL),
                  minRadius: 50,

                ),
              ),

            ],
          ),
          SizedBox(height: 5,),
          AutoSizeText(groupInfo.groupDescription,
            style: TextStyle(fontSize: 14.0, color: Colors.white),
            maxLines: 2,),
          //Text("Kathmandu, Nepal", style: TextStyle(fontSize: 14.0, color: Colors.red.shade700),)
        ],
      ),
    );
  }

  Future<String> getThumbnails(questions questionObj) async {
    String defaultPhoto =
        "https://firebasestorage.googleapis.com/v0/b/advicebee"
        "-9f277.appspot.com/o/noPictureThumbnail.png?alt=media&token=b7189670-"
        "8770-4f85-a51d-936a39b597a1";

    DocumentSnapshot doc = await Firestore.instance
        .collection('users')
        .document(questionObj.createdBy)
        .get();

    return doc["thumbnailPicURL"] == null ? null : doc["thumbnailPicURL"];
  }

  //Get the number of questions in post and display if needed.
  Widget getGroupQuestions(BuildContext context, String groupID) {
    if (postInfoList.length == 0) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.all(8.0),
        child: Text(
          "No questions have been posted yet! Why not be the first?",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18.0,
            color: Colors.grey.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return QuestionCards(CurrentUser, groupID, postInfoList, false, "groups");
    }
  }


  List<questions> getPosts(QuerySnapshot query) {
    //Create local list
    List<questions> postInfo = new List();


    for(DocumentSnapshot doc in query.documents) {
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
                doc["anonymous"] == null ? false : doc["anonymous"],
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
                doc["anonymous"] == null ? false : doc["anonymous"],
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
                doc["anonymous"] == null ? false : doc["anonymous"],
                doc["multipleResponses"] == null
                    ? false
                    : doc["multipleResponses"],
                doc["imageURL"] == null ? null : doc["imageURL"],
              ));
              break;
            }
        }
    }


    return postInfo;
  }

  Widget buildSettingsIcon() {
    if (CurrentUser != null) {
      if (groupInfo.moderators.contains(CurrentUser.userID)) {
        return InkWell(
          child: IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) =>
                    groupSettingsPage(groupInfo, postInfoList),
              ));
            },
          ),
        );
      } else {
        return Container();
      }
    } else {
      return Container();
    }
  }

  void selectSortType(String choice) {
    //Check if list of posts is null or empty before attempting sorts
    if (postInfoList == null || postInfoList.length < 1) {
      return;
    }

    String newChoice = choice.toLowerCase();
    //Set state of widget and have currentChoice equal to the choice desired. This triggers the future builder to automatically sort to the desired type.
    if (newChoice == "most likes") {
      print("sorting by likes");
      setState(() {
        currentChoice = "most likes";
      });
    } else if (newChoice == "recently added") {
      print("sorting by recently added");
      setState(() {
        currentChoice = "recently added";
      });
    } else if (newChoice == "most viewed") {
      print("sorting by views");
      setState(() {
        currentChoice = "most viewed";
      });
    } else if (newChoice == "most responded") {
      print("Sorting by responses count");
      setState(() {
        currentChoice = "most responded";
      });
    } else {
      print("Couldn't identify sorting method");
    }
  }

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

  List<questions> sortByLikes(List<questions> unSortedList) {
    List<questions> tempList = new List.from(unSortedList);
    List<questions> sortedList = new List();


    //Sorting algorithm to find most liked objects
    for (int i = 0; i < unSortedList.length; i++) {
      int mostLikedIndex = 0;
      for (int j = 1; j < tempList.length; j++) {
        //Check the number of likes, if j's object has more likes then set new index
        if (getLikeCount(tempList[j].likes) >
            getLikeCount(tempList[mostLikedIndex].likes)) {
          mostLikedIndex = j;
        }
      }
      sortedList.add(tempList[mostLikedIndex]);
      tempList.removeAt(mostLikedIndex);
    }

    /*Changes isSelected to true for "Most Likes" and false for everything else
      * to properly highlight the user's selected sorting method*/
    for (int i = 0; i < choices.length; i++) {
      if (choices[i].choice == "Most Likes") {
        choices[i].isSelected = true;
      } else {
        choices[i].isSelected = false;
      }
    }

    return sortedList;
  }

  List<questions> sortByViews(List<questions> unSortedList) {
    List<questions> tempList = new List.from(unSortedList);
    List<questions> sortedList = new List();


    //Sorting algorithm to find most liked objects
    for (int i = 0; i < unSortedList.length; i++) {
      int mostViewedIndex = 0;
      for (int j = 1; j < tempList.length; j++) {
        //Check the number of likes, if j's object has more likes then set new index
        if (tempList[j].views.length > tempList[mostViewedIndex].views.length) {
          mostViewedIndex = j;
        }
      }
      sortedList.add(tempList[mostViewedIndex]);
      tempList.removeAt(mostViewedIndex);
    }


    /*Changes isSelected to true for "Most Viewed" and false for everything else
      * to properly highlight the user's selected sorting method*/
    for (int i = 0; i < choices.length; i++) {
      if (choices[i].choice == "Most Viewed") {
        choices[i].isSelected = true;
      } else {
        choices[i].isSelected = false;
      }
    }
    return sortedList;
  }

  List<questions> sortByDate(List<questions> unSortedList) {
    List<questions> tempList = new List.from(unSortedList);
    List<questions> sortedList = new List();


    //Sorting algorithm to find most recent objects
    for (int i = 0; i < unSortedList.length; i++) {
      int dateIndex = 0;
      for (int j = i+1; j < tempList.length; j++) {
        //Check the number of likes, if j's object is more recent then set new index
        if (tempList[j].datePosted.compareTo(tempList[dateIndex].datePosted) >=
            0) {
          dateIndex = j;
        }
      }
      sortedList.add(tempList[dateIndex]);
      tempList.removeAt(dateIndex);
    }

    /*Changes isSelected to true for "Recently Added" and false for everything else
      * to properly highlight the user's selected sorting method*/
    for (int i = 0; i < choices.length; i++) {
      if (choices[i].choice == "Recently Added") {
        choices[i].isSelected = true;
      } else {
        choices[i].isSelected = false;
      }
    }
    return sortedList;
  }


  List<questions> sortByResponseCount(List<questions> unSortedList) {
    List<questions> tempList = new List.from(unSortedList);
    List<questions> sortedList = new List();


    //Sorting algorithm to find most liked objects
    for (int i = 0; i < unSortedList.length; i++) {
      int mostRespondedIndex = 0;
      for (int j = 1; j < tempList.length; j++) {
        //Check the number of likes, if j's object has more likes then set new index
        if (tempList[j].numOfResponses >
            tempList[mostRespondedIndex].numOfResponses) {
          mostRespondedIndex = j;
        }
      }
      sortedList.add(tempList[mostRespondedIndex]);
      tempList.removeAt(mostRespondedIndex);
    }

    /*Changes isSelected to true for "Most Responded" and false for everything else
      * to properly highlight the user's selected sorting method*/
    for (int i = 0; i < choices.length; i++) {
      if (choices[i].choice == "Most Responded") {
        choices[i].isSelected = true;
      } else {
        choices[i].isSelected = false;
      }
    }

    return sortedList;
  }

  Future<List<questions>> getGroupQuestionsFuture() async {
    QuerySnapshot query = await Firestore.instance
        .collection('groups')
        .document(groupInfo.groupID)
        .collection('groupQuestions')
        .orderBy('dateCreated', descending: true)
        .getDocuments();

    List<questions> unSortedList = getPosts(query);

    for(questions post in unSortedList) {
        post.thumbnailURL = await getThumbnails(post);
      }

    switch(currentChoice)
    {
      case "most likes":
        return sortByLikes(unSortedList);
      case "recently added":
        return sortByDate(unSortedList);
      case "most viewed":
        return sortByViews(unSortedList);
      case "most responded":
        return sortByResponseCount(unSortedList);
      default:
        return unSortedList;
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getGroupInformationFuture,
      builder: (BuildContext context, AsyncSnapshot GroupSnapshot){
        switch(GroupSnapshot.connectionState)
        {
          case ConnectionState.none:
            return loadingScaffold(currentTab, context, key, false, "middleButtonHold4");
          case ConnectionState.active:
          case ConnectionState.waiting:
            return loadingScaffold(currentTab, context, key, false, "middleButtonHold5");
          case ConnectionState.done:
            if(GroupSnapshot.hasData) {
              groupInfo = GroupSnapshot.data;
              getGroupPostInfoFuture = getGroupQuestionsFuture();
              return
                //Added SilverAppBar
                Scaffold(
                  body: NestedScrollView(
                    headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          iconTheme: IconThemeData(color: Colors.white),
                          centerTitle: true,
                          title: Text(groupInfo.groupName),
                          actions: <Widget>[
                            PopupMenuButton<String>(
                              icon: Icon(Icons.sort),
                              onSelected: selectSortType,
                              itemBuilder: (BuildContext context){
                                return choices.map((SortValues choice){
                                  return PopupMenuItem<String>(
                                    value: choice.choice,
                                    child:
                                    Text(choice.choice,
                                      style: TextStyle(color: choice.isSelected==true ? Colors.teal : Colors.black),),
                                  );
                                }).toList();
                              },
                            ),
                            buildSettingsIcon(),
                          ],
                          expandedHeight: 200.0,
                          floating: false,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(

                              background: buildProfileImage()),
                        ),
                      ];
                    },
                    body: RefreshIndicator(
                    onRefresh: () async {
                      var groupInfoRefresh = await getGroupInformation();
                      setState(() {
                        groupInfo = groupInfoRefresh;
                      });
                    },
                      child: FutureBuilder(
                        future: getGroupPostInfoFuture,
                        builder: (BuildContext context, AsyncSnapshot<List<questions>> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.none:
                              return Scaffold(body: Center(child: CircularProgressIndicator(),),);
                            case ConnectionState.active:
                              return Scaffold(body: Center(child: CircularProgressIndicator(),),);
                            case ConnectionState.waiting:
                              return Scaffold(body: Center(child: CircularProgressIndicator(),),);
                            case ConnectionState.done:
                              if (snapshot.hasData) {
                                postInfoList = snapshot.data;
                                return buildProfile();
                              } else {
                                return Stack(
                                  children: <Widget>[
                                    SafeArea(
                                      child: Column(
                                        children: <Widget>[
                                          buildProfileImage(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                          }
                          return null;
                        },
                      ),
                    ),

                  ),


                  //End Added new SilverAppBar
                  floatingActionButton: FloatingActionButton(
                    heroTag: "groupProfHero1",
                    child: CircleAvatar(
                      child: Image.asset(
                        'images/addPostIcon4.png',
                      ),
                      maxRadius: 18,
                    ),
                    onPressed: () {
                      if (CurrentUser.userID == null) {
                        guestUserSignInMessage(context);
                      } else {
                        isUserBanned();
                      }
                    },
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                );
            }
        }
        return loadingScaffold(currentTab, context, key, false, "middleButtonHold3");
      },
    );

  }

  isUserBanned() {
    if (groupInfo.bannedUsers == null ||
        !groupInfo.bannedUsers.contains(CurrentUser.userID)) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
              new postQuestion(groupInfo.groupID, CurrentUser)))
          .then((value) {
        setState(() {});
      });
    } else {
      return Flushbar(
        message: 'You are not allowed to post in this group!',
        duration: Duration(seconds: 3),
        backgroundColor: Colors.teal,
      )..show(context);
    }
  }

  Widget buildProfile() {
    return Stack(
      children: <Widget>[
        SafeArea(
          child: Column(
            children: <Widget>[
              //buildProfileImage(),
              getGroupQuestions(context, groupInfo.groupID),
            ],
          ),
        ),
      ],
    );
  }
}