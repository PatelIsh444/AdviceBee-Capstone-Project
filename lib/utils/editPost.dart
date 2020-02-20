import 'package:v0/MyPosts.dart';
import './validator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../QuestionPage.dart';
import '../MoreMenu.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:auto_size_text/auto_size_text.dart';
import './HeroPhotoViewWrapper.dart';
import 'package:flushbar/flushbar.dart';

/**
 *  This class edits a post
 *  Users should  be allowed to edit only their own posts
 *
 */

class editPost extends StatefulWidget {

  String groupID;
  //List<dynamic> choices;
  String groups_or_topics;
  questions questionObject;
  editPost( this.questionObject, this.groups_or_topics, this.groupID);

  @override
  _editPost createState() => _editPost();
}

class _editPost extends State<editPost> {

  String groupID;
  //List<dynamic> choices;
  String groups_or_topics;  //it stores the value "topic" or "groups" depending on the collection
  questions questionObject;
  GlobalKey key = GlobalKey();

  var selectedValue;
  final responseController = TextEditingController();

  var _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    groupID = widget.groupID;
    groups_or_topics = widget.groups_or_topics;
    questionObject = widget.questionObject;
    //Default the first choice to be the selected choice
    /*widget.choices != null
        ? selectedValue = widget.choices[0]
        : selectedValue = null;
        */
    responseController.value = TextEditingValue(text:questionObject.questionDescription);
  }
  void dispose() {
    responseController.dispose();
    super.dispose();
  }

  ///  Build the widget that will contain the Title and the description of post
  ///
  ///  @param questionObject: instance of object implemented from the
  ///                          class question in QuestionPage.dart
  ///
  ///
  Widget buildQuestionCard(var questionObject) {
    Size screenSize = MediaQuery.of(context).size;

    String questionDescription;
    if (questionObject.questionDescription.length>40){
      questionDescription = questionObject.questionDescription.substring(0, 40) + "...";
    }else{
      questionDescription=questionObject.questionDescription;
    }
    return Card(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: ListTile(
                    title: Text(
                      questionObject.question,
                      style: TextStyle( fontWeight: FontWeight.bold, fontSize: 20.0,),
                    ),
                    subtitle: Text(
                      questionDescription,
                      style: TextStyle( fontWeight: FontWeight.w400, fontSize: 16.0),
                    ),
                  ),
                ),
                addImage(questionObject.imageURL),
              ],
            ),
            Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 17),
                width: screenSize.width,
                child: InkWell(
                  child: AutoSizeText(
                    "Posted " +timeago.format(questionObject.datePosted.toDate()),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              )
            ),
          ],
        )
    );
  }

  ///
  ///  Add image on the top left of the screen if there is any
  ///
  ///  @param imageURL: url where the image is stored on the network
  ///  @return widget
  ///

  Widget addImage(var imageURL) {
    if (imageURL == null)
      return Container();
    else {
      return GestureDetector(
        onTap: () {
          Navigator.push(context,MaterialPageRoute(
              builder: (context) => HeroPhotoViewWrapper(
                imageProvider: CachedNetworkImageProvider(imageURL),
              )
          ));
        },
        child: Hero(
          tag: "image",
          child: Container(
              child: Padding(
                padding: EdgeInsets.only(top: 10, right: 15),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(imageURL),
                  radius: 50,
                ),
              )
          ),
        ),
      );
    }
  }

  ///
  ///  Add from field to edit the post
  ///
  Widget buildQuestionSpecific() {
    return Center(
      child: Container(
        decoration: BoxDecoration(),
        width: MediaQuery.of(context).size.width,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                  child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 17),
                      child: InkWell(
                        child: AutoSizeText(
                          "New description ",
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.0,
                            color: Colors.black,
                          ),
                        ),
                      )
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 0.0),
                child:  TextFormField(
                  controller: responseController,
                  autovalidate: false,
                  onSaved: (value) => responseController.text = value,
                  maxLength: 250,
                  validator: Validator.responseValidator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        backgroundColor: Colors.teal,
        title: Text("Edit your post"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "responseHero",
        child:
          Icon(Icons.check),
          onPressed: () {
            setState(() {
              updatePost();
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(1, context, key, false),
      body: Column(
        children: <Widget>[
          buildQuestionCard(questionObject),
          Form(
            key: _formKey,
            child: buildQuestionSpecific(), //Builds body of post response page, determines appropriate body type
          ),
        ],
      ),
    );
  }

  ///  Update data on database
  Future<void> updatePost() async {
    String questionCollection;
    String firstCollection;
    if (groups_or_topics == "topics") {
      questionCollection = "topicQuestions";
      firstCollection = "topics";
    } else {
      questionCollection = "groupQuestions";
      firstCollection = "groups";
    }

    Firestore.instance
        .collection(firstCollection)
        .document(groupID)
        .collection(questionCollection)
        .document(questionObject.postID)
        .updateData({
            'datePosted': Timestamp.now(),
            'description': responseController.text.toString() ,
        }).then((onValue){
            //go back to the "My post page"
            Navigator.push(context,
                MaterialPageRoute(builder: (context) {
                  return  MyPostPage();
                }));
            //display success message
            Flushbar(
              title: "Success",
              message: "Post edit successful",
              duration: Duration(seconds: 8),
              backgroundColor: Colors.teal,
            ).show(context);
        }).catchError((onError) {
              print("failed"+onError);
              Flushbar(
                title: "Error",
                message: "Could not edit the post: "+onError,
                duration: Duration(seconds: 8),
                backgroundColor: Colors.teal,
              ).show(context);
        });
/*
    Firestore.instance
        .collection(firstCollection)
        .document(groupID)
        .collection(questionCollection)
        .document(questionObject.postID)
        .updateData({'numOfResponses': FieldValue.increment(1)});

    Firestore.instance
        .collection("users")
        .document(CurrentUser.userID)
        .updateData({
      'myResponses': FieldValue.arrayUnion([newResponse]),
      'earnedPoints': FieldValue.increment(10),
    });*/
  }
}
