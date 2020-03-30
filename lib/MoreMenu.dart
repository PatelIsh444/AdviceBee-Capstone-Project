import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:v0/pages/NewChat.dart';
import 'package:v0/services/AuthProvider.dart';

import 'AboutUs.dart';
import 'ContactUs.dart';
import 'EditProfile.dart';
import 'Favorite.dart';
import 'MyPosts.dart';
import 'Notification.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'Profile.dart';
import 'GroupPage.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'FollowerPage.dart';
import 'Leaderboard.dart';
import 'landing.dart';

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

void onShow(GlobalKey btnKey, BuildContext context) {
  PopupMenu.context = context;
  PopupMenu menu = PopupMenu(
      backgroundColor: Colors.teal,
      lineColor: Colors.white70,
      // maxColumn: 2,
      items: [
        MenuItem(
            title: 'About Us',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.info,
              color: Colors.lightGreenAccent,
            )),
        MenuItem(
            title: 'Rate Us',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.paper_plane,
              color: Colors.lightGreenAccent,
            )),
        MenuItem(
            title: 'Top Bees',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.trophy,
              color: Colors.lightGreenAccent,
            )),
        MenuItem(
            title: 'Chat',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              Icons.chat,
              color: Colors.lightGreenAccent,
            )),
      ],
      onClickMenu: onClickMenu,
      // stateChanged: stateChanged,
      onDismiss: () {});
  menu.show(widgetKey: btnKey);
}

/*This widget displays the bottom navigation bar. It is used in the
* bottomNavigationBar property in the "Scaffold" class*/
void onClickMenu(MenuItemProvider item) {
  switch (item.menuTitle) {
    case "About Us":
      {
        Navigator.of(PopupMenu.context).push(MaterialPageRoute(
            builder: (BuildContext context) => AboutUsPage()));
        break;
      }
    case "Rate Us":
      {
        Navigator.of(PopupMenu.context).push(MaterialPageRoute(
            builder: (BuildContext context) => ContactUsPage()));
        break;
      }
    case "Top Bees":
      {
        Navigator.of(PopupMenu.context).push(MaterialPageRoute(
            builder: (BuildContext context) => LeaderboardPage()));

        break;
      }
    case "Chat":
      {
        if (CurrentUser.isNotGuest) {
          Navigator.of(PopupMenu.context).push(MaterialPageRoute(
              builder: (BuildContext context) => NewChatScreen(
                    currentUserId: CurrentUser.userID,
                  )));
        } else {
          guestUserSignInMessage(PopupMenu.context);
        }
        break;
      }
  }
}

final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    new FlutterLocalNotificationsPlugin();

void registerNotification() {
  firebaseMessaging.requestNotificationPermissions();
  firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
    print('onMessage: $message');
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

Future onSelectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: ' + payload);
  }
}

Widget globalNavigationBar(
    int currentTab, BuildContext context, GlobalKey key, bool isFirstPage) {
  Size screenSize = MediaQuery.of(context).size;
  registerNotification();
  configLocalNotification();

  if (Platform.isIOS) {
    iOS_Permission();
  }
  return BottomAppBar(
    shape: CircularNotchedRectangle(),
    notchMargin: 10,
    child: Container(
      height: 60,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <
          Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            MaterialButton(
              minWidth: screenSize.width / 5,
              onPressed: () {
                if (currentTab != 0 || !isFirstPage) {
                  //Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Dashboard()),
                      (Route<dynamic> route) => false);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.question_answer,
                    color: currentTab == 0 ? Colors.redAccent : Colors.black,
                    size: 30,
                  ),
                ],
              ),
            ),
            MaterialButton(
              minWidth: screenSize.width / 5,
              onPressed: () {
                if (currentTab != 1 || !isFirstPage) {
                  //Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => GroupPage()),
                      (Route<dynamic> route) => false);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.people,
                    color: currentTab == 1 ? Colors.redAccent : Colors.black,
                    size: 30,
                  ),
                ],
              ),
            )
          ],
        ),

        // Right Tab bar icons

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MaterialButton(
              minWidth: screenSize.width / 5,
              onPressed: () {
                if (!CurrentUser.isNotGuest) {
                  guestUserSignInMessage(context);
                } else {
                  if (currentTab != 2 || !isFirstPage) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                        (Route<dynamic> route) => false);
                  }
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.person,
                    color: currentTab == 2 ? Colors.redAccent : Colors.black,
                    size: 30,
                  ),
                ],
              ),
            ),
            MaterialButton(
              minWidth: screenSize.width / 5,
              onPressed: () {
                if (!CurrentUser.isNotGuest) {
                  guestUserSignInMessage(context);
                } else {
                  if (currentTab != 3 || !isFirstPage) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => NotificationFeed()),
                        (Route<dynamic> route) => false);
                  }
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications,
                    color: currentTab == 3 ? Colors.redAccent : Colors.black,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ]),
    ),
  );
}

Widget globalFloatingActionButton(BuildContext context) {
  return FloatingActionButton(
    child: CircleAvatar(
      child: Image.asset(
        'images/addPostIcon4.png',
      ),
      maxRadius: 18,
    ),
    onPressed: () {},
  );
}
