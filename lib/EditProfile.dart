import 'landing.dart';
import './services/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'Profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'MoreMenu.dart';
import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'QuestionPage.dart';
import './utils/commonFunctions.dart';
class EditProfilePage extends StatefulWidget {
  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  //Declare variables
  final myFormKey = GlobalKey<FormState>();
  GlobalKey key = GlobalKey();

  String fullName = " ";
  String title = " ";
  String bio = " ";
  String followers = " ";
  String posts = " ";
  String scores = " ";
  String imageLink =
      "https://www.google.com/url?sa=i&source=images&cd=&ved=2ahUKEwia8L_r5OfkAhWVCjQIHQ32BQQQjRx6BAgBEAQ&url=https%3A%2F%2Fwww.timlins.co.uk%2Fdefault-profile-54364fb08cf8b2a24e80ed8969012690%2F&psig=AOvVaw0cgNB2NsHEIKWM42o9jQOv&ust=1569357077872937";
  int currentTab = 2;

  /*These variables are to edit the values in the database, whatever the user
  types will be stored into these variables and pushed to firebase*/
  String editFirstName;
  String editTitle;
  String editDescription;

  /*These objects allow the initial values of the form to be set from firebase*/
  final displayName = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  //Reference to the user's Document
  DocumentReference userRef =
      Firestore.instance.collection('users').document(CurrentUser.userID);

  @override
  void initState() {
    super.initState();
    setData();
  }

  //Method to signout
  //Deallocate all routes and end user's session

  Future<void> setData() async {
    userRef.get().then((DocumentSnapshot ds) {
      setState(() {
        if (ds.data["displayName"] != null) {
          displayName.text = ds.data["displayName"];
        }
        if (ds.data["title"] != null) {
          titleController.text = ds.data["title"];
        }
        if (ds.data["bio"] != null) {
          descriptionController.text = ds.data["bio"];
        }
      });
    });
  }

  void printOnSubmit() {
    if (editFirstName != null) {
      print("First name=$editFirstName");
    }
    if (editTitle != null) {
      print("Title=$editTitle");
    }
    if (editDescription != null) {
      print("Description=$editDescription");
    }
  }


  Widget buildEditButton() {
    return Padding(
      //padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      padding: EdgeInsets.only(left: 10, top: 20, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  myFormKey.currentState.save();
                  userRef.updateData({
                    'displayName': editFirstName,
                    'title': editTitle,
                    'bio': editDescription
                  });
                  printOnSubmit();
                  CurrentUser.displayName = editFirstName;
                  print(CurrentUser.displayName);

                  userRef.get().then((DocumentSnapshot doc) {
                    List<dynamic> currentPosts = doc["myPosts"];
                    List<dynamic> currentResponses = doc["myResponses"];
                    for (DocumentReference response in currentResponses) {
                      response.updateData({'userDisplayName': editFirstName});
                    }
                    for (DocumentReference post in currentPosts) {
                      post.updateData({'userDisplayName': editFirstName});
                    }
                  });
                });
                /*Pop the last two pages so users can't go back to the old
                    profile page or the edit page*/
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => ProfilePage()));
                //Sets new followers after increment
              },
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                  color: Color(0xFF009688),
                ),
                child: Center(
                  child: Text(
                    "FINISH EDITING",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //automaticallyImplyLeading: false,
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: new Form(
        key: myFormKey,
        //autovalidate: _autovalidate,
        //onWillPop: _warnUserAboutInvalidData,
        child: new ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            //returnFirstName(),
            new Container(
              child: new TextFormField(
                decoration: const InputDecoration(
                    labelText: "Display Name",
                    hintText: "What do people call you?"),
                autocorrect: false,
                controller: displayName,
                onSaved: (String value) {
                  editFirstName = value;
                },
                maxLength: 24,
                validator: (String value) {
                  if(value.isEmpty) return "Please enter a value";
                  return null;
                },
              ),
            ),
            new Container(
              child: new TextFormField(
                decoration:
                    const InputDecoration(labelText: "Job Title or Status"),
                autocorrect: false,
                controller: titleController,
                onSaved: (String value) {
                  editTitle = value;
                },
                maxLength: 30,
                validator: (String value) {
                  if(value.isEmpty) return "Please enter a value";
                  return null;
                },
              ),
            ),
            new Container(
              child: new TextFormField(
                decoration: const InputDecoration(
                    labelText: "An Interesting Description"),
                autocorrect: false,
                controller: descriptionController,
                onSaved: (String value) {
                  editDescription = value;
                },
                maxLength: 250,
                validator: (String value) {
                  if(value.isEmpty) return "Please enter a value";
                  return null;
                },
              ),
            ),
            buildEditButton(),
          ],
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
        heroTag: "otherPostsHeroz1",
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
