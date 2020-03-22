import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:v0/Profile.dart';
import 'User.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import './utils/commonFunctions.dart' as common;
import 'MoreMenu.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'QuestionPage.dart';


class blockedView extends StatefulWidget {
  @override
  _blockedViewState createState() => _blockedViewState();
}
class _blockedViewState extends State<blockedView> {
  GlobalKey key = GlobalKey();

  List<User> userblocked = [];
  Future<List<User>> userBlockedFuture;

  int get currentTab => null;

  @override
  void initState() {
    super.initState();
    userBlockedFuture = getBlockedUsers();
  }
  Future<List<User>> getBlockedUsers()async
  {
    List<String> blockedList = new List.from(CurrentUser.blocked);
    if (blockedList == null) {
      return buildEmptyBlockList();
    }
    else {
      for (String blockedID in blockedList) {
        User blockedInfo = await common.getUserInformation(blockedID);
        userblocked.add(blockedInfo);
      }
    }
    return userblocked;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: userBlockedFuture,
        builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            case ConnectionState.done:
              if (CurrentUser.blocked.isNotEmpty) {
                userblocked = snapshot.data;
                return Scaffold(
                  // resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("Blocked List"),
                    centerTitle: true,
                  ),
                  body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        blockedUserCards(),
                      ]),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      if (CurrentUser.isNotGuest) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    postQuestion(null, null) //AddPost(),
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
                      maxRadius: 18,
                    ),
                  ),
                  floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar:
                  globalNavigationBar(currentTab, context, key, false),
                );
              }
              else {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("Block List"),
                    centerTitle: true,
                  ),
                  body: ListView(
                    children: buildEmptyBlockList(),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      if (CurrentUser.isNotGuest) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    postQuestion(null, null) //AddPost(),
                            ));
                      } else {
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
                  floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar:
                  globalNavigationBar(currentTab, context, key, false),
                );
              }
          }
          return null;
        });
  }
  buildEmptyBlockList() {
    return <Widget>[SizedBox(
      height: 40.0,
    ),
      Padding(
        padding: EdgeInsets.only(
          top: 5.0,
          left: 30.0,
          right: 30.0,
          bottom: 30.0,),
        child: Text(
          "You have not blocked anyone.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ];
  }

  Widget blockedUserCards() {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
            itemCount: userblocked.length,
            itemBuilder: (context, index) {
              var userObj = userblocked[index];
              return displayMyBlockList(userObj, context, index);
            }),
      ),
    );
  }

  Widget displayMyBlockList(var userObj, BuildContext context, int index) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Card(
          key: Key(userObj.userID),
          elevation: 5,
          child: new InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) =>
                    ProfilePage(),
              ));
            },
            child: ListTile(
              leading: CircleAvatar(
                  backgroundImage:
                  CachedNetworkImageProvider(userObj.profilePicURL)),
              title: Text(userObj.displayName),
              subtitle: Text(userObj.bio),
            ),
          )),
      //actions: <Widget>[],
      secondaryActions: <Widget>[
        IconSlideAction(
            caption: 'Unblocked',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () {
              _confirmBlocked(index);
            }),
      ],
    );
  }

  _confirmBlocked(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("Are you sure you want to block this User?"),
            actions: <Widget>[
              FlatButton(
                  child: Text("Yes"),
                  onPressed: (){
                    setState(() {
                      _deletePost(index);
                    });
                  },
              ),
              FlatButton(
                child: Text("No"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
    );
  }
  Future<void> _deletePost(int index) async {

    Navigator.pop(context);
    setState(() {
      userblocked.removeAt(index);
      CurrentUser.blocked.removeAt(index);
    });
    await Firestore.instance
        .collection("users")
        .document(CurrentUser.userID)
        .updateData({
      'blocked': FieldValue.arrayRemove([CurrentUser.blocked.removeAt(index)])
    });
    Flushbar(
      title: "Success",
      message: "You have just unblocked the user.",
      duration: Duration(seconds: 5),
      backgroundColor: Colors.teal,
    ).show(context);
  }

}

