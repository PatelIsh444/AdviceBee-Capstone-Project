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
//Global userID
var currentUserID;

class OtherUserFollowingFollowersPage extends StatefulWidget {
  //Index for default tab, if you want followers it should be 0, following should be 1
  final tabIndex;
  final otherUserID;
  OtherUserFollowingFollowersPage(this.tabIndex, this.otherUserID);

  @override
  _OtherUserFollowingFollowersPageState createState() => _OtherUserFollowingFollowersPageState();
}

class _OtherUserFollowingFollowersPageState extends State<OtherUserFollowingFollowersPage>
    with SingleTickerProviderStateMixin {
  //Variables
  TabController _tabController;
  final List<Tab> followerTabs = <Tab>[
    Tab(text: "Followers"),
    Tab(text: "Following"),

  ];
  GlobalKey key = GlobalKey();


  List<dynamic> userFollowers = [];
  List<dynamic> userFollowing = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: followerTabs.length, initialIndex: widget.tabIndex);
  }

  Future<void> getFollowers() async {
    List<String> followers;
    await Firestore.instance.collection('users').document(widget.otherUserID).get().then(
          (DocumentSnapshot doc) => followers = doc['followers'],
    );
    setState(() {
      userFollowers = followers;
    });
  }

  Future<void> getFollowing() async {
    List<String> following;
    await Firestore.instance.collection('users').document(widget.otherUserID).get().then(
          (DocumentSnapshot doc) => following = doc['following'],
    );
    setState(() {
      userFollowing = following;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Followers/Following"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: followerTabs,

        ),
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
        heroTag: "efollowerHero",
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
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          OtherFollowersView(widget.otherUserID),
          OtherFollingView(widget.otherUserID),
        ],
      ),
    );
  }
}

class OtherFollowersView extends StatefulWidget {
  final otherUserID;

  OtherFollowersView(this.otherUserID);

  @override
  _OtherFollowersViewState createState() => _OtherFollowersViewState();
}

class _OtherFollowersViewState extends State<OtherFollowersView> {
  //Variables
  List<String> userFollowerIDs;
  List<User> userFollower;
  Future<List<User>> userFollowerFuture;

  @override
  void initState() {
    super.initState();
    userFollowerFuture = getFollowerUsers();
  }

  Future<List<User>> getFollowerUsers() async {
    var followerIDsStr;
    await Firestore.instance.collection('users').document(widget.otherUserID).get().then(
          (DocumentSnapshot doc) => followerIDsStr = doc['followers'],
    );

    //Pull list of followers from user
    List<User> followerUsers = [];
    //List<String> followerIDsStr = new List.from(CurrentUser.followers);

    //Return null if no followers are in firebase
    if(followerIDsStr == null) {
      return null;

    }
    else{
      //Iterate through list of followers and pull their information
      for(String followerID in followerIDsStr)
      {
        User followerInfo = await common.getUserInformation(followerID);
        followerUsers.add(followerInfo);
      }
    }
    return followerUsers;
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: userFollowerFuture,
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
                //If the ID list is empty, return a no followers message

                  userFollower = snapshot.data;
                  if (userFollower !=null && userFollower.length>0) {
                    return Scaffold(
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          generateUserCards(),
                        ],
                      ),
                    );
                  }
          else {
                    return noFollowersPage();
                  }
              } else {
                return noFollowersPage();
              }
          }
          return Scaffold(
              body: Center(
                  child: CircularProgressIndicator()
              )
          );
        });
  }

  Widget noFollowersPage()
  {
    return Padding(
      padding: EdgeInsets.all(20),
      child:Container(
        child: Text(
          "There are no bees here!",
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
            itemCount: userFollower.length,
            itemBuilder: (context, index) {
              var userObj = userFollower[index];
              return Card(
                key: Key(userObj.userID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          UserDetailsPage(userFollower[index].userID),
                    ));
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

class OtherFollingView extends StatefulWidget {
  final otherUserID;
  OtherFollingView(this.otherUserID);

  @override
  _OtherFollingViewState createState() => _OtherFollingViewState();
}

class _OtherFollingViewState extends State<OtherFollingView> {
  //Variables
  List<String> userFollowingIDs;
  List<User> userFollowing;
  Future<List<User>> userFollowingFuture;

  @override
  void initState() {
    super.initState();
    userFollowingFuture = getFollowingUsers();
  }

  Future<List<User>> getFollowingUsers() async {
    var followingIDsStr;
    await Firestore.instance.collection('users').document(widget.otherUserID).get().then(
          (DocumentSnapshot doc) => followingIDsStr = doc['following'],
    );

    //Pull list of followers from user
    List<User> followingUsers = [];
    //List<String> followingIDsStr = new List.from(CurrentUser.following);

    //Return null if no followers are in firebase
    if(followingIDsStr == null) {
      return null;
    }
    else{
      //Iterate through list of followers and pull their information
      for(String followingID in followingIDsStr)
      {
        User followingInfo = await common.getUserInformation(followingID);
        followingUsers.add(followingInfo);
      }
    }
    return followingUsers;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
        future: userFollowingFuture,
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

                  userFollowing = snapshot.data;
                  if(userFollowing !=null && userFollowing.length>0){
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
                  return noFollowingPage();
                }
              } else {
                return noFollowingPage();
              }
          }
          return Scaffold(
              body: Center(
                  child: CircularProgressIndicator()
              )
          );
        });
  }

  //Show when a user does not follow anyone
  Widget noFollowingPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child:Container(
        child: Text(
          "There are no bees here!",
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

  //Generate the cards that a user sees when navigating to the page
  Widget generateUserCards() {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
            itemCount: userFollowing.length,
            itemBuilder: (context, index) {
              var userObj = userFollowing[index];
              return Card(
                key: Key(userObj.userID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          UserDetailsPage(userFollowing[index].userID),
                    ));
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
