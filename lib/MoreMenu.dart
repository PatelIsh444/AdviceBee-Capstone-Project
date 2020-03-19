
import 'Notification.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'Profile.dart';
import 'GroupPage.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'FollowerPage.dart';
import 'Leaderboard.dart';


/*This widget displays the bottom navigation bar. It is used in the
* bottomNavigationBar property in the "Scaffold" class*/
Widget globalNavigationBar(
    int currentTab, BuildContext context, GlobalKey key, bool isFirstPage) {
  Size screenSize = MediaQuery.of(context).size;
  return BottomAppBar(
    shape: CircularNotchedRectangle(),
    notchMargin: 10,
    child: Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: currentTab == 0 ? Colors.teal : Colors.grey,
                    ),
                    Text(
                      'Dash',
                      style: TextStyle(
                        color: currentTab == 0 ? Colors.teal : Colors.grey,
                        fontSize: 12,
                      ),
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
                      color: currentTab == 1 ? Colors.teal : Colors.grey,
                    ),
                    Text(
                      'Hives',
                      style: TextStyle(
                        color: currentTab == 1 ? Colors.teal : Colors.grey,
                        fontSize: 12,
                      ),
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
                          MaterialPageRoute(
                              builder: (context) => ProfilePage()),
                          (Route<dynamic> route) => false);
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person,
                      color: currentTab == 2 ? Colors.teal : Colors.grey,
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: currentTab == 2 ? Colors.teal : Colors.grey,
                        fontSize: 12,
                      ),
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
                              builder: (context) =>  NotificationFeed(
                                  )),
                          (Route<dynamic> route) => false);
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      LineIcons.bell,
                      color: currentTab == 3 ? Colors.teal : Colors.grey,
                    ),
                    Text(
                      'Notification',
                      style: TextStyle(
                        color: currentTab == 3 ? Colors.teal : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
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
