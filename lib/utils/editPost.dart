import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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

import 'commonFunctions.dart';

///
///  This class edits a post
///  Users should  be allowed to edit only their own posts
///
class editPost extends StatefulWidget {
  String groupID;
  String groupsOrTopics;
  questions questionObject;
  List<dynamic> choices;
  editPost( this.questionObject, this.groupsOrTopics, this.groupID,this.choices);

  @override
  _editPost createState() => _editPost();
}

class _editPost extends State<editPost> {

  String groupID;
  List<dynamic> answers;
  List<MultipleChoiceEntry> choices=[];
  String groupsOrTopics;  //it stores the value "topic" or "groups" depending on the collection
  questions questionObject;
  GlobalKey key = GlobalKey();
  File image;
  String imageURL;

  var selectedValue;
  final newDescriptionController = TextEditingController();
  final newTitleController = TextEditingController();
  List<TextEditingController> newChoicesController = [];
  var _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    groupID = widget.groupID;
    answers= widget.choices;
    imageURL=widget.questionObject.imageURL;
    groupsOrTopics = widget.groupsOrTopics;
    questionObject = widget.questionObject;
    newDescriptionController.value = TextEditingValue(text:questionObject.questionDescription);
    newTitleController.value = TextEditingValue(text:questionObject.question);
    if (answers!=null) {
      int index = 0;
      answers.forEach((choice) {
        choices.add(MultipleChoiceEntry());
        print(choice);
        newChoicesController.add(TextEditingController());
        newChoicesController
            .elementAt(index++)
            .value = TextEditingValue(text: choice.toString());
      });
    }
  }
  void dispose() {
    newDescriptionController.dispose();
    newTitleController.dispose();
    super.dispose();
  }

  ///
  ///  Build the widget that will contain the Title and the description of post
  ///
  ///  @param questionObject: instance of object implemented from the
  ///                          class question in QuestionPage.dart
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
  ///  renders the question fields (title, description, etc..)
  ///   and the new field to input
  ///
  Widget buildQuestionSpecific() {
    return Center(
      child: Container(
        decoration: BoxDecoration(),
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            description("New Title"),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 0.0),
              child:  TextFormField(
                controller: newTitleController,
                autovalidate: false,
                onSaved: (value) => newTitleController.text = value,
                maxLength: 60,
                validator: Validator.responseValidator,
              ),
            ),
            description("New Dscription"),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 0.0),
                child:  TextFormField(
                  controller: newDescriptionController,
                  autovalidate: false,
                  onSaved: (value) => newDescriptionController.text = value,
                  maxLength: 250,
                  validator: Validator.responseValidator,
                ),
            ),
            buildMultipleChoiceView(),
            showNewImage(),
            buildAttachImageButton(),
          ],
        ),
      ),
    );
  }

  ///
  /// show new image
  ///
  Widget showNewImage() {
    if (image==null) {
      return Container();
    }else{
      return Image.file(image);
    }
  }

  ///
  /// if the question is multiple choice
  /// this function will display all the choices
  ///
  Widget buildMultipleChoiceView(){
    if(questionObject.questionType!=1) {
      return Container();
    }
    if (choices.length == 0) {
      return Container();
    } else {
      return  showOptions();
    }
  }

  ///
  /// Show the different choices
  ///
  Widget showOptions(){
    if (choices.length == 1) {
      newChoicesController.add(TextEditingController());
      choices.add(MultipleChoiceEntry());
    }
    return Column (
      children: <Widget>[
        description("Choices"),
        ColumnBuilder(
            itemCount: choices.length,
            itemBuilder: (context,index){
              var choice=   choices[index];
              return Dismissible(
                key: Key(choices[index].key.toString()),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                  setState(() {
                    choices.removeAt(index);
                    newChoicesController.removeAt(index);
                  });
                  },
                child: choice.buildMultipleChoiceEntry(newChoicesController[index]),
              );
            }
            ),
        Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 10),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                determineAddButton(),
              ],
            )),
        //determineAddButton(),
      ],
    );
  }

  ///
  /// build the add option button
  ///
  Widget determineAddButton() {
    if (choices.length != 5) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {});
            newChoicesController.add( TextEditingController());
            choices.add(MultipleChoiceEntry());
          },
          child: Container(
            height: 40.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all( Radius.circular(20.0)),
              color: Colors.teal,
            ),
            child: Center(
              child: Text(
                "Add Option",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  ///
  /// upload image to Firebase Storage
  ///
  /// NOTE: after the user selects an image, the image will
  ///       be uploaded even if the user didn't confirm
  ///       However, if the user doesn't confirm, the image url
  ///       will not be modified, so the image show in the question
  ///       page will be the same
  ///
  Future<void> uploadImageToDatabase(String documentID) async {
    if (image != null) {
      if (image.existsSync()) {
        final StorageReference pictureNameInStorage = FirebaseStorage().ref()
            .child("postPictures/" + documentID + "postPicture");
        final StorageUploadTask uploadTask = pictureNameInStorage.putFile(image);
        await uploadTask.onComplete;
        imageURL = await pictureNameInStorage.getDownloadURL() as String;
      }
    }
  }


  ///
  /// create attach image bottom
  ///
  Widget buildAttachImageButton() {
    return Padding(
      padding: EdgeInsets.only(left: 10, top: 8, bottom: 30),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                getImageMenu();
              },
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                  color: Color(0xFF009688),
                ),
                child: Center(
                  child: Text(
                    "Attach Image",
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


  Future getImageMenu() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Snap or Choose a Photo?"),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                    GestureDetector(
                      child: Text("Camera"),
                      onTap: () {
                        getCameraImage();
                      },
                    ),
                    Padding(padding: EdgeInsets.all(7)),
                    GestureDetector(
                      child: Text("Gallery"),
                      onTap: () {
                        getGalleryImage();
                      },
                    ),
                  ])
              )
          );
        });
  }

  ///
  /// this function will display a text message as a row
  ///
  /// @param  description: the String to display
  ///
  Widget description(String description) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
          child: Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 17),
              child: InkWell(
                child: AutoSizeText(
                  description,
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
    );
  }

  getCameraImage() async {
    //Select Image from camera
    Navigator.pop(context);
    var newImage = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: newImage.path,
      cropStyle: CropStyle.circle,
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    );

    setState(() {
      image = croppedImage ?? image;
    });
    if (image.existsSync()) {
      imageUpdatedMessage(context);
    } else {
      imageFailedToUpdateMessage(context);
    }
  }

  getGalleryImage() async {
    //Select Image from gallery
    Navigator.pop(context);
    var newImage = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: newImage.path,
      cropStyle: CropStyle.circle,
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    );

    setState(() {
      image = croppedImage ?? image;
    });

    if (image.existsSync()) {
      imageUpdatedMessage(context);
    } else {
      imageFailedToUpdateMessage(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text("Edit your post"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "responseHero",
        child: Icon(Icons.check),
        onPressed: () {
          updatePost();
          },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(2, context, key, false),
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom
        ),
        child: ListView(
        shrinkWrap: true,
          children: <Widget>[
            Column(
              children: <Widget>[
                buildQuestionCard(questionObject),
                Form(
                  key: _formKey,
                  child: buildQuestionSpecific(), //Builds body of post response page, determines appropriate body type
                ),
              ],
            ),
          ]
      ),
      ),
    );
  }

  ///
  ///  Update data on database
  ///
  Future<void> updatePost() async {
    await uploadImageToDatabase(questionObject.postID);

    String questionCollection;
    String firstCollection;
    if (groupsOrTopics == "topics") {
      questionCollection = "topicQuestions";
      firstCollection = "topics";
    } else {
      questionCollection = "groupQuestions";
      firstCollection = "groups";
    }
    var data;
    if(questionObject.questionType==1) {
      List<String> newChoices= [];
      for(int i =0;i<choices.length;i++){
        newChoices.add(newChoicesController[i].text);
        print(newChoices[i]);
      }
      data = {
        'datePosted': Timestamp.now(),
        'description': newDescriptionController.text.toString(),
        'question': newTitleController.text.toString(),
        'imageURL': imageURL,
        'choices':  newChoices,
      };
    }else{
      data = {
        'datePosted': Timestamp.now(),
        'description': newDescriptionController.text.toString(),
        'question': newTitleController.text.toString(),
        'imageURL': imageURL,
      };
    }

    Firestore.instance
        .collection(firstCollection)
        .document(groupID)
        .collection(questionCollection)
        .document(questionObject.postID)
        .updateData(data).then((onValue){
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
  }
}
