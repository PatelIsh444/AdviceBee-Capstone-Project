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
  createState() => blockedState();

}
class blockedState extends State<blocked> with SingleTickerProviderStateMixin
{
  GlobalKey key = GlobalKey();
  List<dynamic> userblocked = [];

  Future<void> getblocked() async {
    List<String> Blocked;
    await Firestore.instance.collection('users').document(CurrentUser.userID).get().then(
          (DocumentSnapshot doc) => Blocked = doc['blocked'],
    );
    setState(() {
      userblocked = Blocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
           appBar: AppBar(
                  title: Text("Blocked"),
                   centerTitle: true,
              ),
      body:ListView(
          children: <Widget>[
          blockedView(),
      ]
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
         );
  }
}
class blockedView extends StatefulWidget {
  @override
  createState() => blockedViewState();
}
class blockedViewState extends State<blockedView> {
  //Variables
  List<String> BlockedIDs;
  List<User> userBlocked;
  Future<List<User>> userBlockedFuture;

  @override
  void initState() {
    super.initState();
    userBlockedFuture = getBlockedUsers();
  }

  Future<List<User>> getBlockedUsers() async {
    var blockedIDsStr;
    await Firestore.instance.collection('users').document(CurrentUser.userID).get().then(
          (DocumentSnapshot doc) => blockedIDsStr = doc['blocked'],
    );

    //Pull list of followers from user
    List<User> blockedUsers = [];
    //List<String> followingIDsStr = new List.from(CurrentUser.following);

    //Return null if no followers are in firebase
    if(blockedIDsStr == null) {
      return null;
    }
    else{
      //Iterate through list of followers and pull their information
      for(String blockedID in blockedIDsStr)
      {
        User blockedInfo = await common.getUserInformation(blockedID);
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

                userBlocked = snapshot.data;
                if(userBlocked !=null && userBlocked.length>0){
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

  //Show when a user does not follow anyone
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
  //Generate the cards that a user sees when navigating to the page
  Widget generateUserCards() {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
            itemCount: userBlocked.length,
            itemBuilder: (context, index) {
              var userObj = userBlocked[index];
              return Card(
                key: Key(userObj.userID),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          UserDetailsPage(userBlocked[index].userID),
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