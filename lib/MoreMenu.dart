import 'package:v0/pages/NewChat.dart';
import 'AboutUs.dart';
import 'ContactUs.dart';
import 'EditProfile.dart';
import 'MyPosts.dart';
import 'Favorite.dart';
import 'Notification.dart';
import 'landing.dart';
import './services/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:popup_menu/popup_menu.dart';
import 'Profile.dart';
import 'GroupPage.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'FollowerPage.dart';
import 'Leaderboard.dart';

Future<void> _SignOut(BuildContext context) async {
  try {
    final auth = AuthProvider.of(context);
    await auth.SignOut();
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
              color: Colors.white,
            )),
        MenuItem(
            title: 'Rate Us',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.paper_plane,
              color: Colors.white,
            )),
        MenuItem(
            title: 'Top Bees',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.trophy,
              color: Colors.white,
            )),
        MenuItem(
            title: 'Notification',
            textStyle: TextStyle(color: Colors.white, fontSize: 12),
            image: Icon(
              LineIcons.bell,
              color: Colors.white,
            )),
      ],
      onClickMenu: onClickMenu,
      // stateChanged: stateChanged,
      onDismiss: () {});
  menu.show(widgetKey: btnKey);
}

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
    case "Notification":
      {
        Navigator.of(PopupMenu.context).push(MaterialPageRoute(
            builder: (BuildContext context) => NotificationFeed()));
        break;
      }
  }
}

/*When a choice from the more button list is selected this widget is returned.
* It takes the value that was chosen as a string and goes to the selected
* page with the navigator class*/
void moreButtonAction(String choice, BuildContext context) {
  if (choice == 'About Us') {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => AboutUsPage()));
  } else if (choice == 'Settings') {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => EditProfilePage()));
  } else if (choice == 'Notification') {
    Navigator.pushNamed(context, NotificationFeed.id);
  } else if (choice == 'Contact Us') {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => ContactUsPage()));
  } else if (choice == 'My Posts') {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => MyPostPage()));
  } else if (choice == 'Favorites') {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => FavoritePage()));
  } else if (choice == "Followers") {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => FollowingFollowersPage(0)));
  } else if (choice == 'Sign Out') {
    _SignOut(context);
  } else if (choice == 'Leaderboard') {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => LeaderboardPage()));
  }
}

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
                              builder: (context) => NewChatScreen(
                                    currentUserId: CurrentUser.userID,
                                  )),
                          (Route<dynamic> route) => false);
                    }
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.chat,
                      color: currentTab == 3 ? Colors.teal : Colors.grey,
                    ),
                    Text(
                      'Chat',
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
