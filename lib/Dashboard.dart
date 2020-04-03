import 'dart:convert';
import 'dart:io';
import 'package:bottom_navigation_badge/bottom_navigation_badge.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:v0/IntroSlider.dart';
import 'package:v0/pages/NewChat.dart';
import 'EmailVerification.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './Topics.dart';
import 'User.dart' as UserClass;
import 'landing.dart';
import './services/AuthProvider.dart';
import './utils/dialogBox.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import './utils/commonFunctions.dart';
import 'QuestionPage.dart';
import 'SearchBar.dart';
import 'MoreMenu.dart';
import 'QuestionCards.dart' as QuestionCards;
import 'package:flushbar/flushbar.dart';

final activityFeedRef = Firestore.instance.collection('Notification');
final DateTime timestamp = DateTime.now();
final postsRef = Firestore.instance.collection('posts');
final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
final usersRef = Firestore.instance.collection('users');
bool showHeart = false;
final topicsRef = Firestore.instance.collection('topics');
UserClass.User CurrentUser;
const Color gradientStart = const Color(0xFFfbab66);
const Color gradientEnd = const Color(0xFFf7418c);

const chatBubbleGradient = const LinearGradient(
  colors: const [gradientStart, gradientEnd],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

const primaryGradient = const LinearGradient(
  colors: const [gradientStart, gradientEnd],
  stops: const [0.0, 1.0],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class Dashboard extends StatefulWidget {
  static String id = 'dashboard';
  String selectedTopic;
  Dashboard();
  Dashboard.selectedTopic(this.selectedTopic);
  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  int currentTab = 0; // to keep track of active tab index
  GlobalKey key = GlobalKey();
  bool isTopicLoaded = true;
  bool check = true;
  var _userCreated = false;
  List<questions> postList = [];
  Map likes;
  int NumNotification = 90;
  List<Topic> topics = new List();
  String highlightTopic = "All";
  List<String> selectedTopics = new List();
  List<String> allTopicsList = new List();
  List<String> allTopicsName = new List();
  List<SortValues> choices = <SortValues>[
    SortValues("Sort Posts By:", false),
    SortValues("Recently Added", true),
    SortValues("Most Likes", false),
    SortValues("Most Viewed", false),
    SortValues("Most Responded", false),
  ];
  Future<List<String>> getTopicsFuture;
  bool noTopicChange = true;

  //Code for late use: like number format 1K, 1M
  var _formattedNumber = NumberFormat.compact().format(1000);

  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  BottomNavigationBadge badger = new BottomNavigationBadge(
      backgroundColor: Colors.red,
      badgeShape: BottomNavigationBadgeShape.circle,
      textColor: Colors.white,
      position: BottomNavigationBadgePosition.topRight,
      textSize: 8);

  @override
  void initState() {
    getTopicsName();
    //createUser();
    super.initState();
    registerNotification();
    configLocalNotification();

    if (Platform.isIOS) {
      iOS_Permission();
    }
    if (widget.selectedTopic == null) {
      getPosts(null);
    } else {
      highlightTopic = widget.selectedTopic;
      getPosts(widget.selectedTopic);
    }

    topics.add(new Topic(
      "All",
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com"
          "/o/advicebee.png?alt=media&token=f7523657-2d0b-49a6-86d5-6bab8a823526",
    ));
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();
    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      showNotification(message['notification']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      Firestore.instance
          .collection('users')
          .document(CurrentUser.userID)
          .updateData({'pushToken': token, 'last access': 'online'});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void iOS_Permission() {
    firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('icon.png');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(message) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('icon.png');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'mojab.app.advicebee.v0' : 'mojab.app.advicebee.v0',
      'AdviceBee Mobile App',
      'AdviceBee Ask Anything',
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> refreshDashboard() async {
    if (widget.selectedTopic == null) {
      getPosts(null);
    } else {
      highlightTopic = widget.selectedTopic;
      getPosts(widget.selectedTopic);
    }
  }

  //Future function to get topics by name
  Future<void> getTopicsName() async {
    List<String> tempTopics = new List();
    await Firestore.instance
        .collection('topics')
        .orderBy('topicName', descending: false)
        .getDocuments()
        .then((QuerySnapshot data) =>
            data.documents.forEach((doc) => tempTopics.add(
                  doc["topicName"],
                )));
    allTopicsName = tempTopics;
    //topics = tempTopics;
  }
  //Show selecting topic to the User
  showEditTopicMenu(FirebaseUser user) {
    showDialog(
        //barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          //Here we will build the content of the dialog
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
                        "What are your interests? ",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Divider(
                    color: Colors.grey,
                    height: 4.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Container(
                      height: 200.0,
                      child: SingleChildScrollView(
                        child: MultiSelectChip(
                          "topic",
                          allTopicsName,
                          onSelectionChanged: (selectedList) {
                            setState(() {
                              selectedTopics = selectedList;
                              noTopicChange = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _topicOnSelected(user),
                    child: Container(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32.0),
                            bottomRight: Radius.circular(32.0)),
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white, fontSize: 20.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

//Upload selected topic to current user
  _topicOnSelected(FirebaseUser user) async {
    /*Check if selectedTopics is same to myTopics. If they are then there is no
    * topic change, which means there is no point in writing to the database*/
    bool topicListsAreSameSize = selectedTopics != null &&
        CurrentUser.myTopics != null &&
        selectedTopics.length == CurrentUser.myTopics.length;
    if (topicListsAreSameSize) {
      CurrentUser.myTopics.sort((a, b) => a.compareTo(b));
      selectedTopics.sort((a, b) => a.compareTo(b));

      noTopicChange = true;
      for (int i = 0; i < selectedTopics.length; i++) {
        if (selectedTopics[i] != CurrentUser.myTopics[i]) {
          noTopicChange = false;
          break;
        }
      }
    }

    /*This updates the users 'myTopics' field with the selectedTopics list. However,
    if the list is empty we will skip the update to avoid bugs. Also checks if
    topic has actually been clicked/changed so it doesn't delete their topics
    if a user presses edit and confirm without making a selection*/
    if (selectedTopics != null && !noTopicChange) {
      await usersRef.document(user.uid).updateData({
        'myTopics': selectedTopics,
      });

      setState(() {
        CurrentUser.myTopics = selectedTopics;
        noTopicChange = true;
        getTopics();
      });
      Navigator.pushNamed(context, Dashboard.id);
    } else
      Navigator.pop(context);
  }

  Future<List<String>> getTopics() async {
    List<Topic> tempTopics = new List();
    List<String> tempAllTopicsList = new List();
    await Firestore.instance
        .collection('topics')
        .orderBy('topicName', descending: false)
        .getDocuments()
        .then((QuerySnapshot data) =>
            data.documents.forEach((doc) => tempTopics.add(new Topic(
                  doc["topicName"],
                  doc["pictureURL"],
                ))));

    //Clear the topics list except for the first one
    //Avoid adding duplicated topic
    topics.removeWhere((item) => item.name != 'All');
    tempTopics.forEach((temp) {
      tempAllTopicsList.add(temp.name);
    });

    /*Checks if topics field is null in firebase, then adds all topics to their
    * profile*/
    if (CurrentUser.myTopics == null || CurrentUser.myTopics.isEmpty) {
    } else if (_userCreated) {
      tempTopics.forEach((temp) {
        if (CurrentUser.myTopics.contains(temp.name)) {
          topics.add(temp);
        }
      });
    }

    topics.add(new Topic(
      "Edit",
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com"
          "/o/topicIcons%2Fedit.png?alt=media&token=d3552117-6be3-43de-a37d-6"
          "1783038571f",
    ));

    return tempAllTopicsList;
  }

/*
  This function establish user to Firebase after the first login

  SetData to Firebase and then create a new instance of User class
  This function only execute once when the app open
  Pull all user information and store locally
   */
  Future<void> _SignOut(BuildContext context) async {
    try {
      final auth = AuthProvider.of(context);
      await auth.SignOut();
      setUserLastAccess();
      //Destroy all navigation stacks
      Navigator.of(context)
          .pushNamedAndRemoveUntil(MyApp.id, (Route<dynamic> route) => false);
    } catch (e) {
      print(e.toString());
    }
    CurrentUser = null;
  }

  Future<bool> createUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    String qualityPhotoThumbnail =
        "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/noPictureThumbnail.png?alt=media&token=b7189670-8770-4f85-a51d-936a39b597a1";
    if (!_userCreated) {
      // 1) check if user exists in users collection in database (according to their id)
      if (!user.isAnonymous && CurrentUser == null) {
        DocumentSnapshot doc = await usersRef.document(user.uid).get();
        //setUserOnline();
        //Check if user already exists in firebase
        if (!doc.exists) {
          //Change profile picture quality when fetching from Google or Facebook
          var qualityPhoto = user.photoUrl;

          if (qualityPhoto != null) {
            //Fetch high resolution profile photo from Facebook
            if (qualityPhoto.contains('graph.facebook.com')) {
              qualityPhoto = qualityPhoto + "?height=500";
              qualityPhotoThumbnail=qualityPhotoThumbnail+ "?height=500";
            } else  {
              //Fetch high resolution profile photo from Google
              qualityPhoto = qualityPhoto.replaceAll('s96-c', 's400-c');
              qualityPhotoThumbnail=qualityPhotoThumbnail.replaceAll('s96-c', 's400-c');
            }
          } else {
            //Default profile photo
            qualityPhoto =
                "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/noPicture.png?alt=media&token=111de0ef-ae68-422c-850d-8272b48904ab";
            qualityPhotoThumbnail =
               "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/noPictureThumbnail.png?alt=media&token=b7189670-8770-4f85-a51d-936a39b597a1";
          }

          //This method is to retrieve name for user that signed up with email
          //user.displayName is null
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String stringValue = prefs.getString('stringValue');

          // 2) if the user doesn't exist, then we create account page
          await usersRef.document(user.uid).setData({
            'displayName': user.displayName ?? stringValue,
            'email': user.email,
            'profilePicURL': qualityPhoto,
            'thumbnailPicURL': qualityPhotoThumbnail,
            'myPosts': new List(),
            'myTopics': selectedTopics,
            'favoritePosts': new List(),
            'joinedGroups': new List(),
            'followers': new List(),
            'following': new List(),
            'likedPosts': new List(),
            'bio': "An interesting description",
            'earnedPoints': 0,
            'lastPosted': Timestamp.now(),
            'dateCreated': Timestamp.now(),
            'last access': 'online',
            'blocked': new List(),
            'dailyQuestions':3,
            'rank': 'Larvae',
          });

          if (selectedTopics.isEmpty) {
            showEditTopicMenu(user);
          }
        }

        CurrentUser = UserClass.User.fromDocument(doc);
        setUserOnline();
        //If the user logged in with email for the first time then
        //prompt topics selection
      } else if (!user.isEmailVerified &&
          !user.isAnonymous &&
          user.photoUrl == null) {
        //user logged with Facebook email is null but email is verified
        //Bypassed email confirmation for Facebook User
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerification(),
            ));
      }
      //if guest then set isGuest as false
      else if (user.isAnonymous) {
          CurrentUser = UserClass.User.withInfo(isNotGuest: false);

      }
      _userCreated = true;
      getTopicsFuture = getTopics();
    }

    return _userCreated;
  }

//Async function so that pulling information does not block other processes
  Future<bool> getPosts(String topicName) async {
    //Create local list
    List<questions> postInfo = new List();
    if (topicName == null || topicName == "All") {
      //for (String topicname in selectingTopicList) {
      await Firestore.instance
          .collectionGroup('topicQuestions')
          .orderBy('dateCreated', descending: true)
          .getDocuments()
          .then(
            (QuerySnapshot data) => data.documents.forEach(
              (doc) {
                if (doc["topicName"] != null) {
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
                          doc["topicName"],
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
                          doc["topicName"],
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
                          doc["topicName"],
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
                }
              },
            ),
          );
      //}
    } else {
      //topicName = topicName.toLowerCase();
      print("Getting $topicName's posts");

      await Firestore.instance
          .collection('topics')
          .document(topicName)
          .collection('topicQuestions')
          .orderBy('dateCreated', descending: true)
          .getDocuments()
          .then((QuerySnapshot data) => data.documents.forEach((doc) {
                if (doc["topicName"] != null) {
                  switch (doc["questionType"]) {
                    case 0:
                      {
                        postInfo.add(
                          new basicQuestionInfo(
                            doc.documentID,
                            doc["question"],
                            doc["description"],
                            doc["createdBy"],
                            doc["userDisplayName"],
                            doc["dateCreated"],
                            doc["numOfResponses"],
                            doc["questionType"],
                            doc["topicName"],
                            doc["likes"],
                            doc["views"],
                            doc["reports"],
                            doc["anonymous"],
                            doc["multipleResponses"] == null
                                ? false
                                : doc["multipleResponses"],
                            doc["imageURL"] == null ? null : doc["imageURL"],
                          ),
                        );
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
                          doc["topicName"],
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
                          doc["topicName"],
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
                }
              }));
    }

    postList = postInfo;
    if (choices[2].isSelected) {
      sortByLikes();
    } else if (choices[3].isSelected) {
      sortByViews();
    } else if (choices[4].isSelected) {
      sortByResponseCount();
    }

    getThumbnails();
    if (postInfo == null || (postInfo != null && postInfo.length < 1)) {
      emptyTopic(context, topicName);
    }
    return true;
  }

  Widget emptyTopic(BuildContext context, String topicName) {
    return Flushbar(
      title: "No Posts!",
      message:
          "There are no posts in $topicName right now. Be the first to post!",
      duration: Duration(seconds: 6),
      backgroundColor: Colors.teal,
    )..show(context);
  }

  Future<void> getThumbnails() async {
    for (questions questionObj in postList) {
      Firestore.instance
          .collection('users')
          .document(questionObj.createdBy)
          .get()
          .then((DocumentSnapshot ds) {
        setState(() {
          if (questionObj.anonymous == false) {
            questionObj.thumbnailURL = ds['profilePicURL'];
          } else {
            questionObj.thumbnailURL = ds['thumbnailPicURL'] ;
          }
        });
      });
    }
  }

  void selectSortType(String choice) {
    //Check if list of posts is null or empty before attempting sorts
    if (postList == null || postList.length < 1) {
      return;
    }

    String newChoice = choice.toLowerCase();
    if (newChoice == "most likes") {
      print("sorting by likes");
      sortByLikes();
    } else if (newChoice == "recently added") {
      print("sorting by recently added");
      sortByDate();
    } else if (newChoice == "most viewed") {
      print("sorting by views");
      sortByViews();
    } else if (newChoice == "most responded") {
      print("Sorting by responses count");
      sortByResponseCount();
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

  void sortByLikes() {
    List<questions> tempList = new List();
    List<questions> sortedList = new List();

    /*Add all items from postList to tempList, DO NOT USE tempList=postList, as this
    * changes the memory location only and will result in postList losing half of it's
    * values everytime this function is called*/
    for (int i = 0; i < postList.length; i++) {
      tempList.add(postList[i]);
    }

    //Sorting algorithm to find most liked objects
    for (int i = 0; i < postList.length; i++) {
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

    setState(() {
      postList = sortedList;

      /*Changes isSelected to true for "Most Likes" and false for everything else
      * to properly highlight the user's selected sorting method*/
      for (int i = 0; i < choices.length; i++) {
        if (choices[i].choice == "Most Likes") {
          choices[i].isSelected = true;
        } else {
          choices[i].isSelected = false;
        }
      }
    });
  }

  void sortByViews() {
    List<questions> tempList = new List();
    List<questions> sortedList = new List();

    /*Add all items from postList to tempList, DO NOT USE tempList=postList, as this
    * changes the memory location only and will result in postList losing half of it's
    * values everytime this function is called*/
    for (int i = 0; i < postList.length; i++) {
      tempList.add(postList[i]);
    }

    //Sorting algorithm to find most liked objects
    for (int i = 0; i < postList.length; i++) {
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

    setState(() {
      postList = sortedList;

      /*Changes isSelected to true for "Most Viewed" and false for everything else
      * to properly highlight the user's selected sorting method*/
      for (int i = 0; i < choices.length; i++) {
        if (choices[i].choice == "Most Viewed") {
          choices[i].isSelected = true;
        } else {
          choices[i].isSelected = false;
        }
      }
    });
  }

  void sortByDate() {
    List<questions> tempList = new List();
    List<questions> sortedList = new List();

    /*Add all items from postList to tempList, DO NOT USE tempList=postList, as this
    * changes the memory location only and will result in postList losing half of it's
    * values everytime this function is called*/
    for (int i = 0; i < postList.length; i++) {
      tempList.add(postList[i]);
    }

    //Sorting algorithm to find most liked objects
    for (int i = 0; i < postList.length; i++) {
      int dateIndex = 0;
      for (int j = 1; j < tempList.length; j++) {
        //Check the number of likes, if j's object has more likes then set new index
        if (tempList[j].datePosted.compareTo(tempList[dateIndex].datePosted) >=
            0) {
          dateIndex = j;
        }
      }
      sortedList.add(tempList[dateIndex]);
      tempList.removeAt(dateIndex);
    }

    setState(() {
      postList = sortedList;

      /*Changes isSelected to true for "Recently Added" and false for everything else
      * to properly highlight the user's selected sorting method*/
      for (int i = 0; i < choices.length; i++) {
        if (choices[i].choice == "Recently Added") {
          choices[i].isSelected = true;
        } else {
          choices[i].isSelected = false;
        }
      }
    });
  }

  void sortByResponseCount() {
    List<questions> tempList = new List();
    List<questions> sortedList = new List();

    /*Add all items from postList to tempList, DO NOT USE tempList=postList, as this
    * changes the memory location only and will result in postList losing half of it's
    * values everytime this function is called*/
    for (int i = 0; i < postList.length; i++) {
      tempList.add(postList[i]);
    }

    //Sorting algorithm to find most liked objects
    for (int i = 0; i < postList.length; i++) {
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

    setState(() {
      postList = sortedList;

      /*Changes isSelected to true for "Most Responded" and false for everything else
      * to properly highlight the user's selected sorting method*/
      for (int i = 0; i < choices.length; i++) {
        if (choices[i].choice == "Most Responded") {
          choices[i].isSelected = true;
        } else {
          choices[i].isSelected = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /*
    All components of the dashboard
    -AppBar
    -AddPost button
    -TopicList
    -QuestionCard
     */

    //Placeholder for the horizontal scrollview of topics
    Container topicsList;
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text('Dashboard'),
          leading:MaterialButton(
            key: key,
            minWidth: MediaQuery.of(context).size.width / 5,
            onPressed: () {
              onShow(key, context);
            },
            child: Icon(
              Icons.menu,
              color: Colors.white,
              size: 30,
            ),
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              icon: Icon(Icons.sort, size: 30,),
              onSelected: selectSortType,
              itemBuilder: (BuildContext context) {
                return choices.map((SortValues choice) {
                  return PopupMenuItem<String>(
                    value: choice.choice,
                    child: Text(
                      choice.choice,
                      style: TextStyle(
                          color: choice.isSelected == true
                              ? Colors.teal
                              : Colors.black),
                    ),
                  );
                }).toList();
              },
            ),
            IconButton(
              icon: Icon(Icons.search,size: 30,),
              onPressed: () async {
                await showSearch(
                    context: context, delegate: TestSearch(getSearchBarData()));
              },
            ),
          ]),
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
        heroTag: "dashboardHero1",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 12
          ,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, true),
      body: RefreshIndicator(
        onRefresh: refreshDashboard,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            FutureBuilder(
              future: Future.wait([
                createUser(),
                getTopicsFuture,
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData) {
                  allTopicsList = snapshot.data[1];
                  /*
                  These two functions are used to build a horizontal listview that contains
                  a list of topics
                   */
                  final listOfTopics = isTopicLoaded
                      ? Container(
                          height: 65.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: topics
                                .map((topic) => _buildTopicCard(topic, context))
                                .toList(),
                          ),
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        );
                  topicsList = Container(
                    margin: EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 1.0,
                        ),

                        listOfTopics
                      ],
                    ),
                  );
                }
                //If the post list has nothing in it return some empty space.
                if (postList == null || postList.isEmpty) {
                  return Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(
                          child: Text(
                        " ",
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      )));
                }
                //Build the topics and the question cards onto the page.
                return Column(

                  children: <Widget>[

                    topicsList,
                    QuestionCards.QuestionCards(
                        CurrentUser, highlightTopic, postList, true, "topics"),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _processOntapTopic(String name) async {
    FirebaseUser user = await _firebaseAuth.currentUser();

    if (name == "Edit") {
      if (CurrentUser.isNotGuest) {
        showEditTopicMenu(user);
      } else {
        guestUserSignInMessage(context);
      }
    } else {
      highlightTopic = name;
      getPosts(name).catchError((err) {
        //Catch async exception if the selected topic has no posts.
        setState(() {
          postList = null;
        });
      });
    }
  }

/*
  This widget build a single column of Topic
  Contain topic's name and photo
   */
  Widget _buildTopicCard(Topic topic, BuildContext context) {
    final firstName = topic.name.split(" ")[0];
    //print(firstName);
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () => {
            _processOntapTopic(topic.name)
          },
          child: Stack(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(right: 6.0, left: 2.0),
                height: 50.0,
                width: 50.0,
                decoration: BoxDecoration(
                  image: new DecorationImage(
                    image: new CachedNetworkImageProvider(topic.photo),
                    fit: BoxFit.cover,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                height: 65,
                width: 50,
                child: Padding(
                  padding: EdgeInsets.only(top: 50, left: 4.0),
                  child: AutoSizeText(
                    firstName,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: firstName == highlightTopic
                        ? TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          )
                        : TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/*Class for the sorting methods, contains the choice and 'isSelected'
* By default they will all be false except for 'Recently Added' as this will
* be the default sorting method.*/
class SortValues {
  String choice;
  bool isSelected;

  SortValues(this.choice, this.isSelected);
}
