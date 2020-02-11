import 'GroupPage.dart';
import 'GroupProfile.dart';
import 'QuestionPage.dart';
import 'newProfile.dart';
import './utils/commonFunctions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'Dashboard.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'MoreMenu.dart';

class NotificationFeed extends StatefulWidget {
  static String id = 'notification';

  @override
  _NotificationFeedState createState() => _NotificationFeedState();
}

class _NotificationFeedState extends State<NotificationFeed> {
  final activityFeedRef = Firestore.instance.collection('Notification');
  GlobalKey key = GlobalKey();

  List<NotificationItems> notificationItemList = [];

  Stream GetNotification() {
    return activityFeedRef
        .document(CurrentUser.userID)
        .collection('NotificationItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  final image = Image.asset('images/empty.png');

  final notificationHeader = Container(
    padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
    child: Text(
      "No New Notification",
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0),
    ),
  );
  final notificationText = Text(
    CurrentUser.isNotGuest ? "You currently do not have any unread notifications." : "Guests don't receive notifications!!!",
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
      color: Colors.grey.withOpacity(0.6),
    ),
    textAlign: TextAlign.center,
  );

  Future getDeleteMenu() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Delete all notifications?"),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                GestureDetector(
                  child: Text("Yes"),
                  onTap: () {
                    for (NotificationItems notification
                        in notificationItemList) {
                      Firestore.instance
                          .collection('Notification')
                          .document(CurrentUser.userID)
                          .collection("NotificationItems")
                          .document(notification.docID)
                          .delete();
                    }

                    Navigator.pop(context);
                    setState(() {
                      notificationItemList = new List();
                    });
                  },
                ),
                Padding(padding: EdgeInsets.all(7)),
                GestureDetector(
                  child: Text("No"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ])));
        });
  }

  buildNoNotification() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 40.0,
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 50.0,
            left: 30.0,
            right: 30.0,
            bottom: 12.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[image, notificationHeader, notificationText],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: CurrentUser.isNotGuest ? getDeleteMenu :  null,
        tooltip: 'Increment',
        child: Icon(
          Icons.delete_forever,
          size: 42,
        ),
        heroTag: "notificationHero",
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(3, context, key, false),
      body: Container(
          child: StreamBuilder(
        stream: GetNotification(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.documents.length == 0) {
              return buildNoNotification();
            } else {
              if (notificationItemList.length == 0) {
                for (DocumentSnapshot doc in snapshot.data.documents) {
                  if (doc['type'] == 'like' ||
                      doc['type'] == 'follow' ||
                      doc['type'] == 'responded') {
                    notificationItemList
                        .add(NotificationItemsUser.fromDocument(doc));
                  } else if (doc['type'] == 'advisor' ||
                      doc['type'] == 'moderator') {
                    notificationItemList
                        .add(NotificationItemsGroup.fromDocument(doc));
                  } else if (doc['type'] == 'advisorHelp') {
                    notificationItemList
                        .add(NotificationItemsPost.fromDocument(doc));
                  } else if (doc['type'] == 'groupAccept' ||
                      doc['type'] == 'groupDecline')
                    notificationItemList
                        .add(NotificationItemsJoin.fromDocument(doc));
                }
              }
            }
            return ListView.builder(
                itemCount: notificationItemList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Dismissible(
                    key: Key(notificationItemList[index].docID),
                    background: Container(
                      alignment: AlignmentDirectional.centerStart,
                      color: Colors.red,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(5.0, 0, 0, 0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onDismissed: (direction) {
                      notificationItemList[index].removeNotification();
                      notificationItemList.removeAt(index);
                    },
                    child: notificationItemList[index],
                  );
                });
          }
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      )),
    );
  }
}

abstract class NotificationItems extends StatelessWidget {
  String NotificationItemText;
  String docID;

  void configNotificationItem();

  Future<void> removeNotification() async {}
}

//Class for when a private group accepts or declines a user
class NotificationItemsJoin extends StatelessWidget
    implements NotificationItems {
  final String type;
  final String groupID;
  final String groupName;
  String groupProfileImg;
  final Timestamp timestamp;

  bool wasAccepted = false;

  @override
  String NotificationItemText;

  @override
  String docID;

  NotificationItemsJoin({
    this.type,
    this.groupID,
    this.groupName,
    this.groupProfileImg,
    this.timestamp,
    this.docID,
  });

  factory NotificationItemsJoin.fromDocument(DocumentSnapshot doc) {
    return NotificationItemsJoin(
      groupProfileImg: doc['profileImg'],
      type: doc['type'],
      groupID: doc['groupID'],
      timestamp: doc['timestamp'],
      groupName: doc['groupName'],
      docID: doc.documentID,
    );
  }

  @override
  configNotificationItem() {
    if (type == 'groupAccept') {
      NotificationItemText = "You have been accepted into $groupName!";
      //Set flag if user was accepted
      wasAccepted = true;
    } else if (type == 'groupDecline') {
      NotificationItemText = "You have been rejected from $groupName.";
      //Set flag if user was declined
      wasAccepted = false;
    }
    if (groupProfileImg == null) {
      groupProfileImg = 'http://www.getdirectadvice.com/images/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    configNotificationItem();
    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () {
              (wasAccepted)
                  ? Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                      return new GroupProfile.withID(
                        groupID,
                      );
                    }))
                  : Container();
            },
            child: RichText(
              overflow: TextOverflow.visible,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: groupName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '\n'),
                    TextSpan(
                      text: '$NotificationItemText',
                    ),
                  ]),
            ),
          ),
          leading: GestureDetector(
            onTap: () {
              (wasAccepted)
                  ? Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                      return new GroupProfile.withID(
                        groupID,
                      );
                    }))
                  : Container();
              removeNotification();
            },
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(groupProfileImg),
            ),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> removeNotification() async {
    await Firestore.instance
        .collection("Notification")
        .document(CurrentUser.userID)
        .collection("NotificationItems")
        .document(docID)
        .delete();
  }
}

class NotificationItemsUser extends StatelessWidget
    implements NotificationItems {
  final String type;
  final String postId;
  String userProfileImg;
  final String username;
  final Timestamp timestamp;
  final String userId;
  final String groups_or_topics;
  final String groupOrTopicID;

  @override
  String NotificationItemText;

  @override
  String docID;

  NotificationItemsUser({
    this.type,
    this.postId,
    this.userProfileImg,
    this.username,
    this.timestamp,
    this.userId,
    this.groups_or_topics,
    this.groupOrTopicID,
    this.docID,
  });

  factory NotificationItemsUser.fromDocument(DocumentSnapshot doc) {
    return NotificationItemsUser(
      username: doc['username'],
      userId: doc['userId'],
      userProfileImg: doc['userProfileImg'],
      type: doc['type'],
      postId: doc['postId'],
      timestamp: doc['timestamp'],
      groups_or_topics: doc["groups_or_topics"],
      groupOrTopicID: doc["groupOrTopicID"],
      docID: doc.documentID,
    );
  }

  @override
  configNotificationItem() {
    if (type == 'like') {
      NotificationItemText = "liked your post";
    } else if (type == 'follow') {
      NotificationItemText = "is following you";
    } else if (type == 'response') {
      NotificationItemText = "responded";
    } else if (type == 'advisor') {
      NotificationItemText = 'You are now an Advisor!';
    } else if (type == 'moderator') {
      NotificationItemText = 'You are now a Moderator!';
    } else {
      NotificationItemText = "An error has occured.";
    }
    if (userProfileImg == null) {
      userProfileImg = "http://www.getdirectadvice.com/images/logo.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    configNotificationItem();
    return InkWell(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return new PostPage.withID(postId, groups_or_topics, groupOrTopicID);
        }))
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 2.0),
        child: Container(
          color: Colors.white54,
          child: ListTile(
            title: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return new PostPage.withID(
                      postId, groups_or_topics, groupOrTopicID);
                }));
              },
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $NotificationItemText',
                      )
                    ]),
              ),
            ),
            leading: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return new UserDetailsPage(
                    userId,
                  );
                }));
              },
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(userProfileImg),
              ),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> removeNotification() async {
    await Firestore.instance
        .collection("Notification")
        .document(CurrentUser.userID)
        .collection("NotificationItems")
        .document(docID)
        .delete();
  }
}

class NotificationItemsGroup extends StatelessWidget
    implements NotificationItems {
  final String type;
  final String groupID;
  String profileImg;
  final String groupName;
  final Timestamp timestamp;
  final String userID;

  @override
  String docID;

  NotificationItemsGroup({
    this.type,
    this.groupID,
    this.profileImg,
    this.groupName,
    this.timestamp,
    this.userID,
    this.docID,
  });

  @override
  String NotificationItemText;

  factory NotificationItemsGroup.fromDocument(DocumentSnapshot doc) {
    return NotificationItemsGroup(
      type: doc['type'],
      groupID: doc['groupID'],
      profileImg: doc['profileImg'],
      groupName: doc['groupName'],
      timestamp: doc['timestamp'],
      userID: CurrentUser.userID,
      docID: doc.documentID,
    );
  }

  @override
  Widget build(BuildContext context) {
    configNotificationItem();
    return InkWell(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return new GroupProfile.withID(groupID);
        }))
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 2.0),
        child: Container(
          color: Colors.white54,
          child: ListTile(
              title: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return new GroupProfile.withID(
                      groupID,
                    );
                  }));
                },
                child: RichText(
                  overflow: TextOverflow.visible,
                  text: TextSpan(
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: groupName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '\n'),
                        TextSpan(
                          text: '$NotificationItemText',
                        ),
                      ]),
                ),
              ),
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return new GroupProfile.withID(
                      groupID,
                    );
                  }));
                },
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profileImg),
                ),
              ),
              subtitle: Text(
                timeago.format(timestamp.toDate()),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                children: <Widget>[
                  SizedBox(
                    height: 10.0,
                  ),
                  GestureDetector(
                    child: Text("Accept"),
                    onTap: () {
                      Flushbar(
                        message: "You have accepted the invitation!",
                        duration: Duration(seconds: 5),
                        backgroundColor: Colors.teal,
                      )..show(context);
                      removeNotification();
                    },
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  GestureDetector(
                    child: Text("Decline"),
                    onTap: () {
                      removeAdvisorRole();
                      Flushbar(
                        message: "You have declined the invitation!",
                        duration: Duration(seconds: 5),
                        backgroundColor: Colors.teal,
                      )..show(context);
                      removeNotification();
                    },
                  )
                ],
              )),
        ),
      ),
    );
  }

  Future<void> removeAdvisorRole() async {
    await Firestore.instance.collection('groups').document(groupID).updateData({
      type + 's': FieldValue.arrayRemove([userID]),
    });
    removeNotification();
  }

  @override
  void configNotificationItem() {
    if (type == 'advisor') {
      NotificationItemText =
          'You have been invited to be an advisor at $groupName!';
    } else if (type == 'moderator') {
      NotificationItemText =
          'You have been invited to be a moderator at $groupName!';
    } else {
      NotificationItemText = "An error has occured.";
    }
    if (profileImg == null) {
      profileImg = 'http://www.getdirectadvice.com/images/logo.png';
    }
  }

  @override
  Future<void> removeNotification() async {
    await Firestore.instance
        .collection("Notification")
        .document(CurrentUser.userID)
        .collection("NotificationItems")
        .document(docID)
        .delete();
  }
}

class NotificationItemsPost extends StatelessWidget
    implements NotificationItems {
  final String type;
  final String postID;
  String profileImg;
  final String requestor;
  final Timestamp timestamp;
  final String groups_or_topics;
  final String groupOrTopicID;

  @override
  String docID;

  NotificationItemsPost({
    this.type,
    this.postID,
    this.profileImg,
    this.requestor,
    this.timestamp,
    this.groups_or_topics,
    this.groupOrTopicID,
    this.docID,
  });

  @override
  String NotificationItemText;

  factory NotificationItemsPost.fromDocument(DocumentSnapshot doc) {
    return NotificationItemsPost(
      type: doc['type'],
      postID: doc['postID'],
      profileImg: doc['profileImg'],
      requestor: doc['requestor'],
      timestamp: doc['timestamp'],
      groups_or_topics: doc["groups_or_topics"],
      groupOrTopicID: doc["groupOrTopicID"],
      docID: doc.documentID,
    );
  }

  @override
  Widget build(BuildContext context) {
    configNotificationItem();
    return InkWell(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return new PostPage.withID(postID, groups_or_topics, groupOrTopicID);
        }))
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 2.0),
        child: Container(
          color: Colors.white54,
          child: ListTile(
            title: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return new PostPage.withID(
                      postID, groups_or_topics, groupOrTopicID);
                }));
              },
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: requestor,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $NotificationItemText',
                      )
                    ]),
              ),
            ),
            leading: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return new PostPage.withID(
                      postID, groups_or_topics, groupOrTopicID);
                }));
              },
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(profileImg),
              ),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void configNotificationItem() {
    if (type == 'advisorHelp') {
      NotificationItemText = 'is asking for your help!';
    } else {
      NotificationItemText = "An error has occured.";
    }
    if (profileImg == null) {
      profileImg = "http://www.getdirectadvice.com/images/logo.png";
    }
  }

  @override
  Future<void> removeNotification() async {
    await Firestore.instance
        .collection("Notification")
        .document(CurrentUser.userID)
        .collection("NotificationItems")
        .document(docID)
        .delete();
  }
}
