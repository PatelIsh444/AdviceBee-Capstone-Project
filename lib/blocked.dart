import 'package:v0/UserInfor.dart';
import 'package:v0/pages/NewChat.dart';

import 'User.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'newProfile.dart';
import './utils/commonFunctions.dart' as common;
import 'MoreMenu.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'QuestionPage.dart';
class blocked extends StatefulWidget {
  blocked( );
  @override
  _blockedpageViewState createState() => _blockedpageViewState();
}
class _blockedpageViewState extends State<blocked> with SingleTickerProviderStateMixin
{
  GlobalKey key = GlobalKey();
  List<dynamic> userblocked = [];
  @override
  void initState() {
  super.initState();
  common.getUserInformation(CurrentUser.userID).then((updatedInfo) {
    CurrentUser = updatedInfo;
  });
  }
  Future<void> getblocked() async {
    List<String> blocked;
    await Firestore.instance.collection('users').document().get().then(
          (DocumentSnapshot doc) => blocked = doc['blocked'],
    );
    setState(() {
      userblocked = blocked;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
           appBar: AppBar(
                  title: Text("Blocked List"),
                   centerTitle: true,
              ),
                 body:ListView(
                     children: <Widget>[
                     blockedView(),
                ] ),
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
               heroTag: "eblockedrHero",
                 tooltip: 'Increment',
                 child: CircleAvatar(
                   child: Image.asset(
                         'images/addPostIcon4.png',
                    ),
                       maxRadius: 18,
                        ),
                       ),
                    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                          bottomNavigationBar: globalNavigationBar(2, context, key, false),

         );
  }
}
class blockedView extends StatefulWidget {
  @override
  _blockedViewState  createState() => _blockedViewState();
}
class _blockedViewState extends State<blockedView> {
  //Variables
  List<User> userblocked;
  Future<List<User>> userBlockedFuture;
  BuildContext get key => null;
  @override
  void initState() {
    super.initState();
    userBlockedFuture = getBlockedUsers();
  }
  Future<List<User>> getBlockedUsers() async {
    List<User> blockedUsers = [];
    List<String> blockedIDsStr = new List.from(CurrentUser.blocked);
    if(blockedIDsStr == null) {
      return null;
    }
    else{
      //Iterate through list of followers and pull their information
      for(String BlockedIDs in blockedIDsStr)
      {
        User blockedInfo = await common.getUserInformation(BlockedIDs);
        blockedUsers.add(blockedInfo);
      }
    }
    return blockedUsers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: userBlockedFuture,
        builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Scaffold(
                  body: Center(
                      child: CircularProgressIndicator()
                  )
              );
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Scaffold(
                  body: Center(
                      child: CircularProgressIndicator()
                  )
              );
            case ConnectionState.done:
              if (snapshot.hasData) {
                if (CurrentUser.blocked.isNotEmpty) {
                  userblocked = snapshot.data;
                  return Scaffold(
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        generateUserCards(),
                      ],
                      
                    ),
                  );
                }
                else{
                  return noBlockedPage();
                }
              } else {
                return noBlockedPage();
              }
          }
         return Scaffold(
          body: Center(
                  child: CircularProgressIndicator()
          )
         );
        });
  }
  Widget noBlockedPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child:Container(
        child: Text(
          "You have not blocked anyone",
            textAlign: TextAlign.center,
            style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
    Widget generateUserCards() {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
            itemCount: userblocked.length,
            itemBuilder: (context, index) {
              var userObj = userblocked[index];
              return Card(
                key: Key(userObj.userID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                      NewChatScreen(currentUserId: null),
                   )
      );
                  },
                  child:ListTile(
                    leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(userObj.profilePicURL),),
                    title: Text(userObj.displayName),
                    subtitle: Text(userObj.bio),
                  ),
                ),
              );
            }),
      ),
    );
  }
}