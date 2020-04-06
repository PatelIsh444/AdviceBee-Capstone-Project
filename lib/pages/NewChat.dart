import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../utils/commonFunctions.dart';
import '../Dashboard.dart';
import '../MoreMenu.dart';
import '../QuestionPage.dart';
import './MainChatScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './chat.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'searchUser.dart';
class NewChatScreen extends StatefulWidget {
  final String currentUserId;
  NewChatScreen({Key key, @required this.currentUserId}) : super(key: key);
  @override
  State createState() => NewChatScreenState(currentUserId: currentUserId);
}

class NewChatScreenState extends State<NewChatScreen> {
  NewChatScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  new FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  var primaryColor = Colors.black;
  var themeColor = Colors.teal;
  var greyColor = Colors.grey;

  GlobalKey key = GlobalKey();

  bool isLoading = false;

  int get currentTab => null;

  @override
  void initState() {
    super.initState();
  }

  Set chatsSet = new Set<Widget>();
  Set waitingFromSet = new Set<Widget>();
  Set waitingToSet = new Set<Widget>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        title: Text(
          'Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MainScreen(
                          currentUserId: CurrentUser.userID,
                        )));
          },
          child: Icon(Icons.add_com),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: searchUser());
            },
          ),
        ],
      ),

      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              // List
              Container(
                child: StreamBuilder(
                    stream:
                    Firestore.instance.collection('users').snapshots(),
                    builder: (context, snap) {
                      return StreamBuilder(
                        stream: Firestore.instance
                            .collection('chats')
                            .snapshots(),
                        builder: (context, snapshot) {
                          chatsSet.clear();
                          waitingFromSet.clear();
                          waitingToSet.clear();
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.teal),
                              ),
                            );
                          } else {
                            for (int index = 0;
                            index < snapshot.data.documents.length;
                            index++) {
                              List<DocumentSnapshot> id = snap.data.documents
                                  .where((doc) =>
                              doc.documentID ==
                                  snapshot.data.documents[index]['id'])
                                  .toList();
                              List<DocumentSnapshot> peerId = snap
                                  .data.documents
                                  .where((doc) =>
                              doc.documentID ==
                                  snapshot.data.documents[index]
                                  ['peerId'])
                                  .toList();
                              buildItem(
                                  context,
                                  snapshot.data.documents[index],
                                  id.elementAt(0),
                                  peerId.elementAt(0));
                            }
                            return ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.all(5.0),
                              children: <Widget>[
                                Column(
                                  children: waitingFromSet.toList(),
                                ),
                                Column(
                                  children: chatsSet.toList(),
                                ),
                                Column(
                                  children: waitingToSet.toList(),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    }),
              ),
            ],
          ),
        ],
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
        heroTag: "my2PostsHero",
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
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document,
      DocumentSnapshot idDoc, DocumentSnapshot peerDoc) {
    if (document['peerId'] == currentUserId) {
      if (document.documentID == currentUserId) {} else
      if (document['approved'] == false) {
        waitingFromSet.add(Container(
          child: Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Material(
                    child: Icon(
                      Icons.fiber_new,
                      size: 50.0,
                      color: Colors.blueAccent,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  title: Text(
                    'Name: ${document['displayName']}',
                    style: TextStyle(color: primaryColor),
                  ),
                  subtitle: Text(
                    'Pending your approval...',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                new ButtonBar(children: <Widget>[
                  new FlatButton(
                    child: const Text(
                      'Accept Chat',
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed: () {
                      Firestore.instance
                          .collection('chats')
                          .document(document.documentID)
                          .updateData({'approved': true});
                    },
                  ),
                  new FlatButton(
                    child: const Text('Deny Chat',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Firestore.instance
                          .collection('chats')
                          .document(document.documentID)
                          .delete();
                    },
                  )
                ]),
              ],
            ),
          ),
        ));
      } else if (document['approved'] == true) {
        String lastAccess = " ";
        if (idDoc['last access'] != null) {
          if (idDoc['last access'].toString() == "online") {
            lastAccess = "Online";
          }
          else {
            lastAccess = "Last Access: "+ DateFormat.yMd().add_jm()
                .format(DateTime.fromMillisecondsSinceEpoch(int.parse(idDoc['last access']))).toString();
            print(lastAccess);
          }
        }
        chatsSet.add(Container(
          child: FlatButton(
            child: Card(
              child: ListTile(
                leading: Material(
                  child: document['profilePicURL'] != null
                      ? CachedNetworkImage(
                    placeholder: (context, url) =>
                        Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          padding: EdgeInsets.all(15.0),
                        ),
                    imageUrl: document['profilePicURL'],
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.account_circle,
                    size: 50.0,
                    color: greyColor,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                title: Text(
                  'Name: ${document['displayName']}',
                  style: TextStyle(color: primaryColor),
                ),
                subtitle: Text(
                  lastAccess,
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            onPressed: () {
              String groupChatId;
              if (currentUserId.hashCode <= document['id'].hashCode) {
                groupChatId = '$currentUserId-${document['id']}';
              } else {
                groupChatId = '${document['id']}-$currentUserId';
              }
              print("groupChat: " + groupChatId);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Chat(
                            userId: currentUserId,
                            chatId: groupChatId,
                            peerId: document['id'],
                            peerAvatar: document['profilePicURL'],
                            peerName: document['displayName'],
                          )));
            },
          ),
        ));
      }
    } else if (document['id'] == currentUserId) {
      if (document['peerId'] == currentUserId) {} else
      if (document['approved'] == false) {
        waitingToSet.add(Slidable(
            actionPane: SlidableDrawerActionPane(),
            actionExtentRatio: 0.15,
            secondaryActions: <Widget>[
              IconSlideAction(
                  caption: 'Cancel',
                  color: Colors.red,
                  icon: Icons.cancel,
                  onTap: () {
                    Firestore.instance
                        .collection('chats')
                        .document(document.documentID)
                        .delete();
                  }),
            ],
            child: Container(
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: Material(
                        child: Icon(
                          Icons.chat,
                          size: 30.0,
                          color: Colors.redAccent,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      title: Text(
                        'Name: ${document['peerNickname']}',
                        style: TextStyle(color: primaryColor),
                      ),
                      subtitle: Text(
                        'Pending approval...',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            )));
      } else if (document['approved'] == true) {

        String lastAccess= " ";
        if (peerDoc['last access'] != null) {
          if (peerDoc['last access'].toString() == "online") {
            lastAccess = "Online";
          }
          else {

            lastAccess ="Last access: "+  DateFormat('dd MMM kk:mm')
                .format(DateTime.fromMillisecondsSinceEpoch(
                int.parse(peerDoc['last access'])));
          }
        }
        chatsSet.add(Container(
          child: FlatButton(
            child: Card(
              child: ListTile(
                leading: Material(
                  child: document['peerPhotoUrl'] != null
                      ? CachedNetworkImage(
                    placeholder: (context, url) =>
                        Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          padding: EdgeInsets.all(15.0),
                        ),
                    imageUrl: document['peerPhotoUrl'],
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.account_circle,
                    size: 50.0,
                    color: greyColor,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                title: Text(
                  'Name: ${document['peerNickname']}',
                  style: TextStyle(color: primaryColor),
                ),
                subtitle: Text(
                  lastAccess,
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
            onPressed: () {
              String groupChatId;
              if (currentUserId.hashCode <= document['peerId'].hashCode) {
                groupChatId = '$currentUserId-${document['peerId']}';
              } else {
                groupChatId = '${document['peerId']}-$currentUserId';
              }
              print("groupChat: " + groupChatId);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Chat(
                            userId: currentUserId,
                            chatId: groupChatId,
                            peerId: document['peerId'],
                            peerAvatar: document['peerPhotoUrl'],
                            peerName: document['peerNickname'],
                          )));
            },
          ),
        ));
      }
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});
  final String title;
  final IconData icon;
}
