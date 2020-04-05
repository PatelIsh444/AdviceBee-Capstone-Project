import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'SearchBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MoreMenu.dart';
import './utils/commonFunctions.dart';
import 'Dashboard.dart';
import './utils/GroupInformation.dart';
import 'GroupProfile.dart';

//Constant to be pulled from database in future semesters
const int groupPostCost = 50;

//Group page for Dart, will have create a group button, owned groups button, and other groups.
class GroupPage extends StatefulWidget {
  @override
  _GroupPageState createState() => _GroupPageState();
}

//State widget for group page. (Maybe can be converted to stateless?)
class _GroupPageState extends State<GroupPage> {
  //Variables
  int currentTab = 1;
  bool isUserAnon;
  Future<bool> isUserAnonFuture;
  GlobalKey key = GlobalKey();

  @override
  void initState() {
    super.initState();
    isUserAnonFuture = isAnonymousUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: isUserAnonFuture,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return loadingScaffold(currentTab, context, key, true, "middleButtonHold1");
            case ConnectionState.active:
            case ConnectionState.waiting:
              return loadingScaffold(currentTab, context, key, true, "middleButtonHold2");
            case ConnectionState.done:
              if (snapshot.hasData) {
                isUserAnon = snapshot.data;
                return buildGroupControllers();
              }
          }
          return null;
        });
  }

  Widget buildGroupControllers() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text("Hives"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context, delegate: TestSearch(getSearchBarData()));
              },
            )
          ],
          bottom: TabBar(
            tabs: <Widget>[
              //List all tabs needed for the tab bar, could be text, images, etc.
              Tab(text: "Other Hives"),
              Tab(text: "My Hives"),
            ],
          ),
        ),
        //TabBarView requires exactly as many children as tabs
        body: TabBarView(
          children: <Widget>[
            //Tab for other groups
            Scaffold(
              body: Center(child: OtherGroups()),
            ),
            //Tab for Owned Groups
            Scaffold(
              body: Center(child: myGroupsList(isUserAnon)),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (isUserAnon) {
              guestUserSignInMessage(context);
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => addGroupPage(),
                  ));
            }
          },
          heroTag: "middleButtonHold12",
          tooltip: 'Increment',
          child: Icon(Icons.person_add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: globalNavigationBar(currentTab, context, key, true),
      ),
    );
  }
}

class myGroupsList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _myGroupsListState();
  }

  bool isUserAnon;
  myGroupsList(this.isUserAnon);
}

class _myGroupsListState extends State<myGroupsList> {
//Variables
  List<GroupInformation> joinedGroupInfo = [];
  String userID;
  List<dynamic> groupsJoined = [];

  //Initialize basic state and generate list group. Needed for most dynamic content
  @override
  void initState() {
    super.initState();
    getUserID().then((onValue) {
      userID = onValue;
    });
  }

  Future<String> getUserID() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    return user.uid;
  }

  //Async function so that pulling information does not block other processes
  Future<GroupInformation> getGroups(String groupID) async {
    //Create local list
    GroupInformation groupInfo;

    await Firestore.instance
        .collection('groups')
        .document(groupID)
        .get()
        .then((DocumentSnapshot doc) => groupInfo = (new GroupInformation(
              doc.documentID,
              doc["moderators"],
              doc["groupName"],
              doc["groupDescription"],
              doc["dateCreated"],
              doc["createdBy"],
              doc["groupImage"],
              doc["numOfPosts"],
              doc["privateGroup"],
              doc["advisors"],
              doc["bannedUsers"],
              doc["userRequestToJoin"],
            )));
    return groupInfo;
  }

  //Async function so that pulling information does not block other processes
  Future<void> getJoinedGroups() async {
    //Create local list
    List<dynamic> groups = [];
    await Firestore.instance
        .collection('users')
        .document(userID)
        .get()
        .then((DocumentSnapshot data) => groups = data["joinedGroups"]);

    //Update the state of the widget to include changed files.
    setState(() {
      groupsJoined = groups;
    });
  }

  Future<List<GroupInformation>> getJoinedGroupsStream(
      DocumentSnapshot doc) async {
    //Create local list
    List<GroupInformation> groups = [];
    List<dynamic> groupIDs = doc["joinedGroups"];
    for (var group in groupIDs) {
      await getGroups(group).then((groupInfo) => groups.add(groupInfo));
    }

    groups.sort((a, b) =>
        a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase()));
    return groups;
  }

  Widget buildIsAnonPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
        child: Text(
          "You are not logged in! \nCreate an account to see what the buzz is about! "
          "Press \"More\" and sign out to create an account.",
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

  Widget buildMyGroupsPage() {
    return RefreshIndicator(
      onRefresh: getJoinedGroups,
      child: Scaffold(
        body: ListView.builder(
          itemCount: joinedGroupInfo.length,
          itemBuilder: (context, index) {
            return Card(
              key: Key(joinedGroupInfo[index].groupName),
              elevation: 5,
              child: new InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return new GroupProfile(joinedGroupInfo[index]);
                    }));
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        height: 100.0,
                        child: Row(
                          children: <Widget>[
                            Hero(
                              tag: joinedGroupInfo[index].groupID,
                              child: Container(
                                height: 100.0,
                                width: 90.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(5),
                                      topLeft: Radius.circular(5)),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: CachedNetworkImageProvider(
                                          joinedGroupInfo[index].imageURL)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 3, 0, 0),
                                //Set the formatting for the name
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      //Set the group name for every Card
                                      joinedGroupInfo[index].groupName,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0, 5, 0, 2),
                                      child: Container(
                                        width: 260,
                                        //Set the description for every card
                                        child: Text(
                                          joinedGroupInfo[index]
                                              .groupDescription,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color.fromARGB(
                                                  255, 48, 48, 54)),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 45.0),
                              child: ButtonTheme.bar(
                                //padding: EdgeInsets.only(top: 50.0),
                                alignedDropdown: true,
                                child: ButtonBar(
                                  children: <Widget>[
                                    FlatButton(
                                      child: const Text("Leave"),
                                      onPressed: () {
                                        //Prevent creator of a group from leaving their own group
                                        if (CurrentUser.userID ==
                                            joinedGroupInfo[index].createdBy) {
                                          Flushbar(
                                            message:
                                                'You can\'t leave your own group!',
                                            duration: Duration(seconds: 3),
                                            backgroundColor: Colors.teal,
                                          )..show(context);
                                        } else {
                                          removeGroupFromUserPage(
                                              joinedGroupInfo[index].groupID);
                                          Flushbar(
                                            message:
                                                'You have left ${joinedGroupInfo[index].groupName}!',
                                            duration: Duration(seconds: 3),
                                            backgroundColor: Colors.teal,
                                          )..show(context);
                                          setState(() {
                                            joinedGroupInfo.removeAt(index);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUserAnon) {
      return buildIsAnonPage();
    } else {
      return FutureBuilder(
        future: getUserID(),
        builder: (context, userIDSnapshot) {
          if (userIDSnapshot.hasData) {
            userID = userIDSnapshot.data;
            return StreamBuilder(
              stream: Firestore.instance
                  .collection('users')
                  .document(userID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder(
                    future: getJoinedGroupsStream(snapshot.data),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.hasData) {
                        joinedGroupInfo = futureSnapshot.data;
                        return buildMyGroupsPage();
                      }
                      return Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    },
                  );
                }
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              },
            );
          }
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }
  }

  void removeGroupFromUserPage(String groupID) {
    Firestore.instance.collection("users").document(userID).updateData({
      "joinedGroups": FieldValue.arrayRemove([groupID])
    });
  }
}

//Stateful Widget for OtherGroups tab
class OtherGroups extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OtherGroupListWidget();
  }
}

//ListWidget generates the list of groups avaliable from within the database
class OtherGroupListWidget extends State<OtherGroups> {
  //Variables
  List<GroupInformation> otherGroupsList = [];
  List<dynamic> groupsJoined = new List();
  bool isUserAnon;

  //Initialize basic state and generate list group. Needed for most dynamic content
  @override
  void initState() {
    super.initState();
    if (CurrentUser.userID != null) {
      isUserAnon = false;
      //Get list of joined groups before getting actual list of groups
      getJoinedGroups().then((onValue) {
        getGroups();
      });
    } else {
      isUserAnon = true;
      getGroups();
    }
  }

  //Async function so that pulling information does not block other processes
  Future<void> getGroups() async {
    //Create local list
    List<GroupInformation> groupInfo = new List();

    await Firestore.instance
        .collection('groups')
        .orderBy("groupName")
        .getDocuments()
        .then((QuerySnapshot data) =>
            data.documents.forEach((doc) => groupInfo.add(new GroupInformation(
                  doc.documentID,
                  doc["moderators"],
                  doc["groupName"],
                  doc["groupDescription"],
                  doc["dateCreated"],
                  doc["createdBy"],
                  doc["groupImage"],
                  doc["numOfPosts"],
                  doc["privateGroup"],
                  doc["advisors"],
                  doc["bannedUsers"],
                  doc["userRequestToJoin"],
                ))));

    //Update the state of the widget to include changed files.
    setState(() {
      otherGroupsList = groupInfo;
    });
  }

  //Async function to get groups a user has joined
  Future<void> getJoinedGroups() async {
    //Create local list
    List<dynamic> groups = [];
    await Firestore.instance
        .collection('users')
        .document(CurrentUser.userID)
        .get()
        .then((DocumentSnapshot data) => groups = data["joinedGroups"]);

    //Update the state of the widget to include changed files.
    setState(() {
      groupsJoined = groups;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: getGroups,
      child: Scaffold(
        body: ListView.builder(
          itemCount: otherGroupsList.length,
          itemBuilder: (context, index) {
            if (groupsJoined.contains(otherGroupsList[index].groupID)) {
              return Container();
            } else {
              return Card(
                key: Key(otherGroupsList[index].groupName),
                elevation: 5,
                child: new InkWell(
                    onTap: () {
                      //If the group is private, Display a flushbar stating the user can't view the group
                      //Otherwise, go to that groups profile.
                      if (otherGroupsList[index].privateGroup) {
                        Flushbar(
                          message:
                              'You can not view ${otherGroupsList[index].groupName}!'
                              '\nYou must be a member to view this group!',
                          duration: Duration(seconds: 6),
                          backgroundColor: Colors.teal,
                        )..show(context);
                      } else {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return new GroupProfile(otherGroupsList[index]);
                        }));
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          height: 100.0,
                          child: Row(
                            children: <Widget>[
                              Hero(
                                tag: otherGroupsList[index].groupID,
                                child: Container(
                                  height: 100.0,
                                  width: 90.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(5),
                                        topLeft: Radius.circular(5)),
                                    image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: CachedNetworkImageProvider(
                                            otherGroupsList[index].imageURL)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 3, 0, 0),
                                  //Set the formatting for the name
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        //Set the group name for every Card
                                        otherGroupsList[index].groupName,
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(0, 5, 0, 2),
                                        child: Container(
                                          width: 260,
                                          //Set the description for every card
                                          child: Text(
                                            otherGroupsList[index]
                                                .groupDescription,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Color.fromARGB(
                                                    255, 48, 48, 54)),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 45.0),
                                child: ButtonTheme.bar(
                                  //padding: EdgeInsets.only(top: 50.0),
                                  alignedDropdown: true,
                                  child: joinOrAskButton(
                                      otherGroupsList[index], index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              );
            }
          },
        ),
      ),
    );
  }

  _showCancelRequest(BuildContext context, GroupInformation groupInfo) {
    if (CurrentUser.isNotGuest) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            //Here we will build the content of the dialog
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              contentPadding: EdgeInsets.only(top: 10.0),
              content: Container(
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "Cancel Join Request?",
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Divider(
                      color: Color(0xFFCBD7D0),
                      height: 4.0,
                    ),
                    Padding(
                        padding: EdgeInsets.only(left: 30.0, right: 30.0),
                        child: Image(
                            height: 150,
                            image: new AssetImage('images/giphy.gif'))
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 138.0,
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32.0),
                              ),
                            ),
                            child: Text(
                              "No",
                              style:
                              TextStyle(color: Colors.white, fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 3.0,
                        ),

                        InkWell(
                          onTap: ()async {
                            await removeUserJoinRequest(groupInfo).catchError((err) {
                              print("error removing user");
                            });

                            Navigator.pop(context);

                          },
                          child: Container(
                            width: 138.0,
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.only(
                                // bottomLeft: Radius.circular(32.0),
                                  bottomRight: Radius.circular(32.0)),
                            ),
                            child: Text(
                              "Yes",
                              style:
                              TextStyle(color: Colors.white, fontSize: 20.0),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            );
          });
    } else {
      guestUserSignInMessage(context);
    }
  }


  ButtonBar joinOrAskButton(GroupInformation groupInfo, int index) {
    //If the group is private, display an ask to join button instead of join
    if (groupInfo.userRequestToJoin!=null && groupInfo.userRequestToJoin.contains(CurrentUser.userID)){
      return ButtonBar(
        children: <Widget>[
          FlatButton(
            child: const Text("Pending"),
            onPressed: () {
              if (!isUserAnon) {
                _showCancelRequest(context, groupInfo);
              } else {
                guestUserSignInMessage(context);
              }
            },
          ),
        ],
      );
    }
    else if (groupInfo.privateGroup) {
      return ButtonBar(
        children: <Widget>[
          FlatButton(
            child: const Text("Ask to Join"),
            onPressed: () {
              if (!isUserAnon) {
                sendJoinGroupNotification(groupInfo);
                Flushbar(
                  message: 'You have asked to join ${groupInfo.groupName}!'
                      '\nYou will be notified if you are allowed in!',
                  duration: Duration(seconds: 6),
                  backgroundColor: Colors.teal,
                )..show(context);
              } else {
                guestUserSignInMessage(context);
              }
            },
          ),
        ],
      );
    } else {
      return ButtonBar(
        children: <Widget>[
          FlatButton(
            child: const Text("Join"),
            onPressed: () {
              if (!isUserAnon) {
                addGroupToUserPage(groupInfo.groupID);
                Flushbar(
                  message: 'You have joined ${groupInfo.groupName}!',
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.teal,
                )..show(context);
                setState(() {
                  //Have to recreate list as growable, despite specifying the list as growable originally
                  //Possible bug with flutter? This is the workaround for now.
                  groupsJoined = new List.from(groupsJoined);
                  groupsJoined.add(groupInfo.groupID);
                  otherGroupsList.removeAt(index);
                });
              } else {
                guestUserSignInMessage(context);
              }
            },
          ),
        ],
      );
    }
  }

  Future<void> sendJoinGroupNotification(GroupInformation groupInfo) async {
    await Firestore.instance
        .collection("groups")
        .document(groupInfo.groupID)
        .updateData({
      "userRequestToJoin": FieldValue.arrayUnion([CurrentUser.userID])
    });

    await
    Firestore.instance
        .collection("groups")
        .document(groupInfo.groupID)
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        groupInfo.userRequestToJoin = ds.data["userRequestToJoin"];
      });
    });
  }

  //Function appends new group to users "my groups" list
  Future<void> addGroupToUserPage(String groupID) async {
    Firestore.instance
        .collection("users")
        .document(CurrentUser.userID)
        .updateData({
      "joinedGroups": FieldValue.arrayUnion([groupID])
    });
  }

  //Removes user request from group
  Future<void> removeUserJoinRequest(GroupInformation groupInfo) async {
    await Firestore.instance
        .collection("groups")
        .document(groupInfo.groupID)
        .updateData({
      "userRequestToJoin": FieldValue.arrayRemove([CurrentUser.userID])
    });

    await
    Firestore.instance
        .collection("groups")
        .document(groupInfo.groupID)
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        groupInfo.userRequestToJoin = ds.data["userRequestToJoin"];
      });
    });
  }
}




class addGroupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _addGroupPageState();
  }
}

class _addGroupPageState extends State<addGroupPage> {
  //Variables
  final groupNameController = TextEditingController();
  final groupDescriptionController = TextEditingController();
  GlobalKey key = GlobalKey();
  String get newGroupName => groupNameController.text;
  String get newGroupDescription => groupDescriptionController.text;
  bool privateGroup = false;
  var _firstPress = true;
  var databaseInstance = Firestore.instance.collection('groups');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        title: new Text(
          "Create a group",
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "groupHero",
        child: Icon(Icons.check),
        onPressed: () {
          if (_firstPress) {
            if(_formKey.currentState.validate())
            {
              _firstPress = false;
              createGroup();
            }
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(1, context, key, false),
      body: Center(
        child: Container(
          decoration: BoxDecoration(),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Form(
            key: _formKey,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                    )
                  ],
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                  child: new TextFormField(
                    controller: groupNameController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: new InputDecoration(labelText: 'Group Name'),
                    maxLength: 45,
                    validator: (String value) {
                      if (value.isEmpty) return "Please enter a name";
                      return null;
                    },
                  ),
                ),
                new SizedBox(
                  height: 15.0,
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
                  child: new TextFormField(
                    controller: groupDescriptionController,
                    maxLength: 250,
                    decoration:
                    new InputDecoration(labelText: 'Group Description'),
                    validator: (String value) {
                      if (value.isEmpty) return "Please enter a description";
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 30),
                CheckboxListTile(
                  title: const Text("Private Group?"),
                  value: privateGroup,
                  onChanged: (bool value) {
                    setState(() {
                      privateGroup = value;
                    });
                  },
                  secondary: Icon(Icons.group),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Check to see if a group name is unique
  Future<bool> isGroupNameUnique() async{
   QuerySnapshot groupNameQuery = await Firestore.instance.collection("groups")
    .where("groupName", isEqualTo: groupNameController.text)
    .getDocuments();

   //If there is any document with the same name, then the group's name is not unique
   if(groupNameQuery.documents.length != 0)
     return false;

   //Otherwise, return true
   return true;
  }

  Future<void> createGroup() async {

    //Store async value when function returns
    bool uniqueName = await isGroupNameUnique();

    //If the name is unique, proceed with rest of the process
    if(uniqueName) {
        DocumentReference newGroup = databaseInstance.document();
        List<dynamic> moderators = [CurrentUser.userID];
        List<dynamic> groupID = [newGroup.documentID];
        //If a user is a "queen bee" then they can create a group
        if (CurrentUser.earnedPoints > 999) {
          await newGroup.setData({
            'moderators': FieldValue.arrayUnion(moderators),
            'createdBy': CurrentUser.userID,
            'dateCreated': Timestamp.now(),
            'groupDescription': groupDescriptionController.text,
            'groupImage':
            "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/advicebee.png?alt=media&token=f7523657-2d0b-49a6-86d5-6bab8a823526",
            'groupName': groupNameController.text,
            'numOfPosts': 0,
            'privateGroup': privateGroup,
            'advisors': FieldValue.arrayUnion([CurrentUser.userID]),
            'userRequestToJoin': new List(),
            'bannedUsers': new List(),
          });

          await Firestore.instance
              .collection('users')
              .document(CurrentUser.userID)
              .updateData({
            'joinedGroups': FieldValue.arrayUnion(groupID),
            'earnedPoints': FieldValue.increment(-50),
          });

          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
              settings: RouteSettings(name: "GroupPage"),
              builder: (BuildContext context) => GroupPage()));
        } else {
          _firstPress=true;
          Flushbar(
            title: "Not enough points!",
            message:
            'You do not have enough points to create a group!\n Become a queen bee to create your own group!',
            duration: Duration(seconds: 20),
            backgroundColor: Colors.teal,
          )..show(context);
        }
      }
    else{
      _firstPress=true;
      Flushbar(
        title: "Group name taken!",
        message:
        'This group name is already taken!',
        duration: Duration(seconds: 10),
        backgroundColor: Colors.teal,
      )..show(context);
    }
  }
}
