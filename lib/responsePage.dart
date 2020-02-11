import 'Dashboard.dart';
import './utils/validator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'QuestionPage.dart';
import 'package:flutter/services.dart';
import 'MoreMenu.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:auto_size_text/auto_size_text.dart';
import './utils/HeroPhotoViewWrapper.dart';

class postResponse extends StatefulWidget {
  String questionID;
  String groupOrTopicID;
  questionTypes questionType;
  List<dynamic> choices;
  String groups_or_topics;
  questions questionObject;

  postResponse(this.questionID, this.groupOrTopicID, this.questionType,
      this.groups_or_topics, this.questionObject);

  postResponse.withChoices(this.questionID, this.groupOrTopicID,
      this.questionType, this.choices, this.groups_or_topics, this.questionObject);

  @override
  _PostResponseState createState() => _PostResponseState();
}

class _PostResponseState extends State<postResponse> {
  //Variables
  String questionID;
  String groupOrTopicID;
  GlobalKey key = GlobalKey();

  var selectedValue;
  final responseController = TextEditingController();

  var _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    questionID = widget.questionID;
    groupOrTopicID = widget.groupOrTopicID;

    //Default the first choice to be the selected choice
    widget.choices != null
        ? selectedValue = widget.choices[0]
        : selectedValue = null;
  }

  Widget buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.only(left: 10, top: 8, bottom: 30, right: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                //First, check if the question type is multiple choice
                if (widget.questionType != questionTypes.MULTIPLE_CHOICE) {
                  //If it isn't, validate the response then upload.
                  if (_formKey.currentState.validate()) {
                    uploadResponseToDatabase();
                    Navigator.pop(context);
                  }
                } else {
                  //Otherwise, just upload the response
                  uploadResponseToDatabase();
                  Navigator.pop(context);
                }
              }),
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                  color: Color(0xFF009688),
                ),
                child: Center(
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuestionCard(
      String questionTitle,
      String questionDescription,
      String uDisplayName,
      String createdBy,
      bool isAnonymous,
      var datePosted,
      var imageURL) {
    Size screenSize = MediaQuery.of(context).size;
    if (questionDescription.length>40){
      questionDescription=questionDescription.substring(0, 40) + "...";
    }
    return Card(
        child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: ListTile(
                title: Text(
                  questionTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                subtitle: Text(
                  questionDescription,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            addImage(imageURL),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 17),
          width: screenSize.width,
          child: GestureDetector(
              child: InkWell(
                child: AutoSizeText(
                  isAnonymous
                      ? "Posted by Anonymous " +
                          timeago.format(datePosted.toDate())
                      : "Posted by " +
                          uDisplayName +
                          " " +
                          timeago.format(datePosted.toDate()),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              onTap: () {}),
        ),
      ],
    ));
  }

  Widget addImage(var imageURL) {
    if (imageURL == null)
      return Container();
    else {
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HeroPhotoViewWrapper(
                        imageProvider: CachedNetworkImageProvider(imageURL),
                      )));
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
          )),
        ),
      );
    }
  }

  //Function determines layout needed for type of question
  Widget buildQuestionSpecific() {
    switch (widget.questionType) {
      case questionTypes.SHORT_ANSWER:
        {
          return Center(
            child: Container(
              decoration: BoxDecoration(),
              width: MediaQuery.of(context).size.width,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: new TextFormField(
                      controller: responseController,
                      decoration:
                          new InputDecoration(labelText: 'Enter Response!'),
                      autovalidate: false,
                      onSaved: (value) => responseController.text = value,
                      maxLength: 60,
                      validator: Validator.responseValidator,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      case questionTypes.MULTIPLE_CHOICE:
        {
          return //Column(
            //children: <Widget>[
              //Build out list of responses
              Expanded(
                child: ListView.builder(
                    itemCount: widget.choices.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.choices[index].toString()),
                        leading: Radio(
                            value: widget.choices[index],
                            groupValue: selectedValue,
                            onChanged: (value) {
                              setState(() {
                                selectedValue = value;
                              });
                            }),
                      );
                    }),
              );
            //],
         // );
        }
      case questionTypes.NUMBER_VALUE:
        {
          return Center(
            child: Container(
              decoration: BoxDecoration(),
              width: MediaQuery.of(context).size.width,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 0.0),
                    child: new TextFormField(
                      controller: responseController,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                      keyboardType: TextInputType.number,
                      decoration:
                          new InputDecoration(labelText: 'Enter a Number!'),
                      autovalidate: false,
                      onSaved: (value) => responseController.text = value,
                      maxLength: 5,
                      validator: Validator.responseValidator,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        backgroundColor: Colors.teal,
        title: Text("Post a Response"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "responseHero",
        child: Icon(Icons.check),
        onPressed: () {
          setState(() {
            //First, check if the question type is multiple choice
            if (widget.questionType != questionTypes.MULTIPLE_CHOICE) {
              //If it isn't, validate the response then upload.
              if (_formKey.currentState.validate()) {
                uploadResponseToDatabase();
                Navigator.pop(context);
              }
            } else {
              //Otherwise, just upload the response
              uploadResponseToDatabase();
              Navigator.pop(context);
            }
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(1, context, key, false),
      body: Column(
        children: <Widget>[
                  buildQuestionCard(widget.questionObject.question, widget.questionObject.questionDescription, widget.questionObject.userDisplayName, widget.questionObject.createdBy, widget.questionObject.anonymous, widget.questionObject.datePosted, widget.questionObject.imageURL == null ? null : widget.questionObject.imageURL ),
                  Form(
                    key: _formKey,
                    child:
                        buildQuestionSpecific(), //Builds body of post response page, determines appropriate body type
                  ),
        ],
      ),
    );
  }

  //Function to upload the response to the database
  void uploadResponseToDatabase() {
    String questionCollection;
    String firstCollection;
    if (widget.groups_or_topics == "topics") {
      questionCollection = "topicQuestions";
      firstCollection = "topics";
      //groupOrTopicID=groupOrTopicID.toLowerCase(); //Topic should be lowercase
    } else {
      questionCollection = "groupQuestions";
      firstCollection = "groups";
    }

    DocumentReference newResponse = Firestore.instance
        .collection(firstCollection)
        .document(groupOrTopicID)
        .collection(questionCollection)
        .document(questionID)
        .collection('responses')
        .document();

    switch (widget.questionType) {
      case questionTypes.SHORT_ANSWER:
        newResponse.setData({
          'answer': responseController.text.toString(),
          'createdBy': CurrentUser.userID,
          'datePosted': Timestamp.now(),
          'likes': {},
          'userDisplayName': CurrentUser.displayName,
        });
        break;
      case questionTypes.MULTIPLE_CHOICE:
        newResponse.setData({
          'answer': selectedValue,
          'createdBy': CurrentUser.userID,
          'datePosted': Timestamp.now(),
          'likes': {},
          'userDisplayName': CurrentUser.displayName,
        });
        break;
      case questionTypes.NUMBER_VALUE:
        newResponse.setData({
          'answer': (double.parse(responseController.text)),
          'createdBy': CurrentUser.userID,
          'datePosted': Timestamp.now(),
          'likes': {},
          'userDisplayName': CurrentUser.displayName
        });
        break;
    }
    Firestore.instance
        .collection(firstCollection)
        .document(groupOrTopicID)
        .collection(questionCollection)
        .document(questionID)
        .updateData({'numOfResponses': FieldValue.increment(1)});

    Firestore.instance
        .collection("users")
        .document(CurrentUser.userID)
        .updateData({
      'myResponses': FieldValue.arrayUnion([newResponse]),
      'earnedPoints': FieldValue.increment(10),
    });
  }
}
