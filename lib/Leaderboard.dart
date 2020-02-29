import 'Dashboard.dart';
import 'Profile.dart';
import './utils/commonFunctions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'newProfile.dart';
import 'MoreMenu.dart';
import 'UserInfor.dart';
import 'QuestionPage.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<LeaderboardInformation> topUsers = new List();

  var userRanks = new List();
 GlobalKey  key  = GlobalKey();

  @override
  void initState() {
    super.initState();
    getTopUsers();
  }

  Future<void> getTopUsers() async {
    List<LeaderboardInformation> tempTopUsers = new List();

    await Firestore.instance.collection('users').getDocuments().then(
          (QuerySnapshot data) => data.documents.forEach(
            (doc) {
              tempTopUsers.add(new LeaderboardInformation(
                doc.documentID == null ? null : doc.documentID,
                doc["profilePicURL"] == null ? null : doc["profilePicURL"],
                doc["displayName"] == null ? null : doc["displayName"],
                doc["myTopics"] == null ? null : doc["myTopics"],
                (doc["dailyPoints"] == null ? 0 : doc["dailyPoints"]) +
                    (doc["earnedPoints"] == null ? 0 : doc["earnedPoints"]),
                doc["rank"] == null ? null : doc["rank"],
                false,
              ));
            },
          ),
        );

    setState(() {
      if (tempTopUsers.length > 0) {
        topUsers = sortListByPoints(tempTopUsers);
      }
    });
  }

  /*Sorts list of users by their points, returns a list with 5 of the highest ranked users.
  * Can change the number of users by changing the number in while condition, ex: i<#numberOfTopUsersWanted#*/
  List<LeaderboardInformation> sortListByPoints(
      List<LeaderboardInformation> userList) {
    List<LeaderboardInformation> topFiveUsers = new List();
    int i = 0;

    while (i < 5 && i < userList.length) {
      int maxPoints = 0;

      for (int j = 0; j < userList.length; j++) {
        if (userList[maxPoints].totalPoints < userList[j].totalPoints) {
          maxPoints = j;
        }
      }

      String tempRank;
      if (userList[maxPoints].totalPoints<500)
        tempRank="Larvae";
      else if (userList[maxPoints].totalPoints>=500 && userList[maxPoints].totalPoints<1000)
        tempRank="Worker Bee";
      else
        tempRank="Queen Bee";

      userRanks.add(tempRank);
      topFiveUsers.add(new LeaderboardInformation(
          userList[maxPoints].id,
          userList[maxPoints].photoUrl,
          userList[maxPoints].displayName,
          userList[maxPoints].topics,
          userList[maxPoints].totalPoints,
          userList[maxPoints].rank,
          false));
      userList.removeAt(maxPoints);
      i++;
    }

    return topFiveUsers;
  }

  Widget buildTopUserCards() {
    return Expanded(
      child: SizedBox(
        height: 200.0,
        child: ListView.builder(
            itemCount: topUsers.length,
            itemBuilder: (context, index) {
              var userObj = topUsers[index];
              return Card(
                key: Key(userObj.id),
                elevation: 5,
                child: new InkWell(
                  onTap: () {
                    if (CurrentUser.userID == userObj.id){
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) =>
                            ProfilePage(),
                      ));
                    }
                    else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) =>
                            UserDetailsPage(userObj.id),
                      ));
                    }
                  },
                  child:
                      /*ListTile(
                    leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(userObj.photoUrl),),
                    title: Text(userObj.displayName),
                    subtitle: Text("rank"),
                  ),*/
                      Stack(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(userObj.photoUrl),
                            minRadius: 30,
                            maxRadius: 30,
                          )),
                      Padding(
                        padding: EdgeInsets.only(left: 73, top: 5, bottom: 5),
                        child: Stack(
                          children: <Widget>[
                            Text(userObj.displayName + "\n",
                            style: TextStyle(fontWeight: FontWeight.bold),),
                            Text("\n${userObj.totalPoints} Total Points (${userRanks[index]})"),
                            pickTopThreeTopics(userObj),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  //Function that goes through topic list of user and picks up to their top three topics
  Text pickTopThreeTopics(LeaderboardInformation user){
    String topics = " No Preference";

    if (user.topics != null && user.topics.length>0){
      int i =0;
      topics=" ";
      while (i<3 && i<user.topics.length){
        topics+=user.topics[i];
        if (i != 2 && i!= user.topics.length-1)
          topics+= ", ";

        i++;
      }
    }

    return Text("\n\nTopics:$topics");
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard"),
        centerTitle: true,
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
        heroTag: "leaderBoardHero1",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 18,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(3, context, key, false),
      body: topUsers == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildTopUserCards(),
              ],
            ),
    );
  }
}
