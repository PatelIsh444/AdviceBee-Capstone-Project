import 'package:v0/pages/NewChat.dart';
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
  _blockedViewState  createState() => _blockedViewState();
}
class _blockedViewState extends State<blockedView> {
  GlobalKey key = GlobalKey();

  //check this  one  ->

  //List<User> userblocked = new List();
  
  List<User>userblocked;
  Future<List<User>> userBlockedFuture;
  int get currentTab => null;
  @override
  void initState()
  {
    super.initState();
    userBlockedFuture = getBlockedUsers();
  }
  Future<List<User>> getBlockedUsers() async {
    List<User> userblocked1 = [];
    List<String> blockedList = new List.from(CurrentUser.blocked);
    //Return null if no followers are in firebase
    if(blockedList == null)
    {
      return null;
    }
    else
      {
      //Iterate through list of followers and pull their information
      for(String blockedID in blockedList)
      {
        User blockedInfo = await common.getUserInformation(blockedID);
        userblocked1.add(blockedInfo);
      }
    }
    return userblocked1;
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
             // if (snapshot.hasData) {
                if (CurrentUser.blocked.isNotEmpty) {
                  userblocked = snapshot.data;
                  return Scaffold(
                    // resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                      title: Text("Blocked List"),
                      centerTitle: true,
                    ),
                    body:Column (
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children:<Widget>[
                        generateUserCards(),
                      ]
                    ),
                    floatingActionButton:
                    FloatingActionButton(
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
                    floatingActionButtonLocation: FloatingActionButtonLocation
                        .centerDocked,
                    bottomNavigationBar: globalNavigationBar(
                        currentTab, context, key, false),
                  );
                }
             // }
              else {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    title: Text("My Post"),
                    centerTitle: true,
                  ),
                  body: ListView(
                      children: <Widget>[
                    noBlockedPage(),]
                  ),
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
                    heroTag: "my1PostsHero",
                    tooltip: 'Increment',
                    child: CircleAvatar(
                      child: Image.asset(
                        'images/addPostIcon4.png',
                      ),
                      maxRadius: 18,
                    ),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
                );
              }
              }
              return null;
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