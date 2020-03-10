import 'package:flutter/cupertino.dart';

import 'AboutUs.dart';
import 'ContactUs.dart';
import 'Favorite.dart';
import 'FollowerPage.dart';
import 'GroupPage.dart';
import 'Leaderboard.dart';
import 'MyPosts.dart';
import './utils/dialogBox.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import './utils/commonFunctions.dart';
import 'SearchBar.dart';
import 'package:line_icons/line_icons.dart';
import 'EditProfile.dart';
import 'MoreMenu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'Dashboard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'QuestionPage.dart';
import './utils/commonFunctions.dart';
import 'package:image/image.dart' as im;

import 'pages/MainChatScreen.dart';
import 'pages/MoreQuestions.dart';
import 'pages/NewChat.dart';

class ProfilePage extends StatefulWidget {
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  File _image;
  String fullName = "";
  String bio = "An Interesting Description";
  String followers = "0";
  String following = "0";
  String posts = "0";
  String scores = "100";
  String rank = "None";
  String title;
  String imageLink = "https://firebasestorage.googleapis.com"
      "/v0/b/advicebee-9f277.appspot.com/o/noPicture.png?"
      "alt=media&token=111de0ef-ae68-422c-850d-8272b48904ab";
  String rankImage =
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
      "appspot.com/o/rankIcons%2FLarvae.png?alt=media&token=9afeb4c7-dbaf-"
      "4f8f-9885-3906155ed612";
  int currentTab = 2;
  GlobalKey key = GlobalKey();
  bool noTopicChange = true;
  String dateJoined = "October 2019";

  List<String> selectedTopics = List();

  //Added list of all available Topics
  List<String> allTopicsList = new List();

  _showReportDialog() {
    showDialog(
        //barrierDismissible: true,
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
                        "What are your interests? ",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Divider(
                    color: Colors.grey,
                    height: 4.0,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Container(
                      height: 200.0,
                      child: SingleChildScrollView(
                        child: MultiSelectChip(
                          "topic",
                          allTopicsList,
                          onSelectionChanged: (selectedList) {
                            setState(() {
                              selectedTopics = selectedList;
                              noTopicChange = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _topicOnSelected(),
                    child: Container(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32.0),
                            bottomRight: Radius.circular(32.0)),
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white, fontSize: 20.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  _topicOnSelected() async {
    /*Check if selectedTopics is same to myTopics. If they are then there is no
    * topic change, which means there is no point in writing to the database*/
    bool topicListsAreSameSize = selectedTopics != null &&
        CurrentUser.myTopics != null &&
        selectedTopics.length == CurrentUser.myTopics.length;
    if (topicListsAreSameSize) {
      CurrentUser.myTopics.sort((a, b) => a.compareTo(b));
      selectedTopics.sort((a, b) => a.compareTo(b));

      noTopicChange = true;
      for (int i = 0; i < selectedTopics.length; i++) {
        if (selectedTopics[i] != CurrentUser.myTopics[i]) {
          noTopicChange = false;
          break;
        }
      }
    }

    /*This updates the users 'myTopics' field with the selectedTopics list. However,
    if the list is empty we will skip the update to avoid bugs. Also checks if
    topic has actually been clicked/changed so it doesn't delete their topics
    if a user presses edit and confirm without making a selection*/
    if (selectedTopics != null && !noTopicChange) {
      await usersRef.document(CurrentUser.userID).updateData({
        'myTopics': selectedTopics,
      });

      setState(() {
        CurrentUser.myTopics = selectedTopics;
        noTopicChange = true;
      });
    }

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  //Get data from firebase
  Future<void> getData() async {
    Firestore.instance
        .collection('users')
        .document(CurrentUser.userID)
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        if (ds.data["displayName"] != null) {
          fullName = ds.data["displayName"];
        }
        if (ds.data["title"] != null) {
          title = ds.data["title"];
        }
        if (ds.data["bio"] != null) {
          bio = ds.data["bio"];
        }
        if (ds.data["followers"] != null) {
          dynamic followerCount = ds.data["followers"];
          followers = followerCount.length.toString();
        }
        if (ds.data["following"] != null) {
          dynamic followingCount = ds.data["following"];
          following = followingCount.length.toString();
        }
        if (ds.data["myPosts"] != null) {
          dynamic postCount = ds.data["myPosts"];
          posts = postCount.length.toString();
        }
        if (ds.data["earnedPoints"] != null || ds.data["dailyPoints"] != null) {
          if (ds.data["earnedPoints"] == null) {
            scores = ds.data["dailyPoints"].toString();
          } else if (ds.data["dailyPoints"] == null) {
            scores = ds.data["earnedPoints"].toString();
          } else {
            scores =
                (ds.data["earnedPoints"] + ds.data["dailyPoints"]).toString();
          }
        }
        if (ds.data["profilePicURL"] != null) {
          imageLink = ds.data["profilePicURL"];
        }
        if (ds.data["rank"] != null) {
          rank = ds.data["rank"];
        }
        if (ds.data["rankImage"] != null) {
          rankImage = ds.data["rankImage"];
        }
        if (ds.data["dateCreated"] != null) {
          DateTime timeStampSplit = (ds.data["dateCreated"]).toDate();
          dateJoined =
              getMonth(timeStampSplit.month) + timeStampSplit.year.toString();
          print(dateJoined);
        }
        setRank();

        //Call to get all Topics
        getTopics();
      });
    });
  }

  //Future function to get topics by name
  Future<void> getTopics() async {
    List<String> tempTopics = new List();
    await Firestore.instance
        .collection('topics')
        .orderBy('topicName', descending: false)
        .getDocuments()
        .then((QuerySnapshot data) =>
            data.documents.forEach((doc) => tempTopics.add(
                  doc["topicName"],
                )));

    setState(() {
      allTopicsList = tempTopics;
      //topics = tempTopics;
    });
  }

  Future<void> setRank() async {
    int tempScores = int.parse(scores);
    if (tempScores < 500) {
      if (rank == "Worker Bee" || rank == "Queen Bee")
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return demotedMessage(context, "500");
            });
      rank = "Larvae";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2FLarvae.png?alt=media&token=9afeb4c7-dbaf-"
          "4f8f-9885-3906155ed612";
    } else if (tempScores >= 500 && tempScores < 1000) {
      if (rank == "Larvae") {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return promotedMessage(context, "500");
            });
      } else if (rank == "Queen Bee") {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return demotedMessage(context, "1000");
            });
      }
      rank = "Worker Bee";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2Fbee.png?alt=media&token=80bd21e2-f795-"
          "46f4-a273-4d5653dfa414";
    } else {
      if (rank == "Worker Bee" || rank == "Larvae")
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return promotedMessage(context, "1000");
            });
      rank = "Queen Bee";
      rankImage = "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277."
          "appspot.com/o/rankIcons%2FqueenBee2.png?alt=media&token=c4b425ed-"
          "76c8-44fb-a933-5ca00031168b";
    }
    Firestore.instance
        .collection('users')
        .document(CurrentUser.userID)
        .updateData({'rank': rank});
  }

  AlertDialog demotedMessage(BuildContext context, String pointAmount) {
    String rankName;
    if (pointAmount == "500") {
      rankName = "Worker Bee";
    } else if (pointAmount == "1000") {
      rankName = "Queen Bee";
    } else {
      rankName = "Unknown";
    }

    return AlertDialog(
        title: Text("Reverse Promotion!"),
        content: SingleChildScrollView(
            child: ListBody(children: <Widget>[
          Text("You have $scores points, get to $pointAmount and you will"
              " be promoted to $rankName."),
          Container(
            width: 80,
            height: 50,
            child: GestureDetector(
              child: Text(
                "\nContinue",
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ])));
  }

  AlertDialog promotedMessage(BuildContext context, String pointAmount) {
    String rankName, nextRankName;
    if (pointAmount == "500") {
      rankName = "Worker Bee";
      nextRankName = "Get to 1000 and you will be promoted to Queen Bee.";
    } else if (pointAmount == "1000") {
      rankName = "Queen Bee";
      nextRankName = "You have proven yourself as the biggest bee in the hive! "
          "There is no higher prestige than Queen Bee. Thank you for"
          " helping out your fellow bees!";
    } else {
      rankName = "Unknown";
      nextRankName = " ";
    }

    //Dialog if they reach 500-1000 points
    return AlertDialog(
        title: Text("Bee Promotion!"),
        content: SingleChildScrollView(
            child: ListBody(children: <Widget>[
          Text("You have $scores points, you are now a $rankName. "
              "$nextRankName"),
          Container(
            width: 80,
            height: 50,
            child: GestureDetector(
              child: Text(
                "\nContinue",
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ])));
  }

  Widget buildRank(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return rankInformationMessage(context);
              });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                image: new DecorationImage(
                  image: new CachedNetworkImageProvider(rankImage),
                ),
              ),
            ),
            Text(
              " " + rank + " ",
              style: TextStyle(
                fontFamily: 'Spectral',
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                image: new DecorationImage(
                  image: new CachedNetworkImageProvider(rankImage),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Chooses an image from the camera then uploads it to firebase storage.
  * After image is successfully uploaded, it returns a message notifying them*/
  getCameraImage() async {
    //Select Image from camera
    Navigator.pop(context);
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: image.path,
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
      _image = croppedImage ?? _image;
    });

    /*This code will be visited if the user actually selects a photo from
    their gallery or takes a picture with a camera. If they press the back
    button on their phone the image will be null and this code will not be
    visited*/
    if (croppedImage != null) {
      //Upload Image
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("profilePictures/" + CurrentUser.userID + "profilePicture");
      final StorageUploadTask uploadTask = pictureNameInStorage.putFile(_image);
      await uploadTask.onComplete;

      //Resize image to thumbnail
      var tImage = im.decodeImage(File(_image.path).readAsBytesSync());
      var thumbnailImage = im.copyResize(tImage, width: 100, height: 100);
      File(_image.path)..writeAsBytesSync(im.encodePng(thumbnailImage));

      //Upload thumbnail
      final StorageReference thumbnailPictureNameInStorage = FirebaseStorage()
          .ref()
          .child("profilePictures/" +
              CurrentUser.userID +
              "profileThumbnailPicture");
      final StorageUploadTask uploadTask2 =
          thumbnailPictureNameInStorage.putFile(_image);
      await uploadTask2.onComplete;

      var imageURL = await pictureNameInStorage.getDownloadURL() as String;
      var thumbnailImageURL =
          await thumbnailPictureNameInStorage.getDownloadURL() as String;
      Firestore.instance
          .collection('users')
          .document(CurrentUser.userID)
          .updateData({
        'profilePicURL': imageURL,
        'thumbnailPicURL': thumbnailImageURL,
      });

      setState(() {
        getData();
      });

      // return showDialog(context: context, builder: (BuildContext context) {
      if (uploadTask.isSuccessful) {
        imageUpdatedMessage(context);
      } else {
        imageFailedToUpdateMessage(context);
      }
      // });
    }
  }

  /*Chooses an image from the gallery then uploads it to firebase storage.
  * After image is successfully uploaded, it returns a message notifying them*/
  getGalleryImage() async {
    //Select Image from gallery
    Navigator.pop(context);
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 65);

    File croppedImage = await ImageCropper.cropImage(
      sourcePath: image.path,
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
      //maxWidth: 160,
      //maxHeight: 160,
    );

    setState(() {
      _image = croppedImage ?? _image;
    });

    /*This code will be visited if the user actually selects a photo from
    their gallery or takes a picture with a camera. If they press the back
    button on their phone the image will be null and this code will not be
    visited*/
    if (croppedImage != null) {
      //Upload image
      final StorageReference pictureNameInStorage = FirebaseStorage()
          .ref()
          .child("profilePictures/" + CurrentUser.userID + "profilePicture");
      final StorageUploadTask uploadTask = pictureNameInStorage.putFile(_image);
      await uploadTask.onComplete;

      //Resize image to thumbnail
      var tImage = im.decodeImage(File(_image.path).readAsBytesSync());
      var thumbnailImage = im.copyResize(tImage, width: 100, height: 100);
      File(_image.path)..writeAsBytesSync(im.encodePng(thumbnailImage));

      //Upload thumbnail
      final StorageReference thumbnailPictureNameInStorage = FirebaseStorage()
          .ref()
          .child("profilePictures/" +
              CurrentUser.userID +
              "profileThumbnailPicture");
      final StorageUploadTask uploadTask2 =
          thumbnailPictureNameInStorage.putFile(_image);
      await uploadTask2.onComplete;

      var imageURL = await pictureNameInStorage.getDownloadURL() as String;
      var thumbnailImageURL =
          await thumbnailPictureNameInStorage.getDownloadURL() as String;
      setState(() {
        Firestore.instance
            .collection('users')
            .document(CurrentUser.userID)
            .updateData({
          'profilePicURL': imageURL,
          'thumbnailPicURL': thumbnailImageURL,
        });
        getData();
      });

      if (uploadTask.isSuccessful) {
        imageUpdatedMessage(context);
      } else {
        imageFailedToUpdateMessage(context);
      }
    }
  }

  /*Button action calls this function, this function displays the options
  the user has, they can choose Camera or Gallery*/
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
              ])));
        });
  }

  //Update Image
  Future<void> updateImage() async {
    await Firestore.instance
        .collection('users')
        .document(CurrentUser.userID)
        .get()
        .then((DocumentSnapshot ds) {
      setState(() {
        if (ds.data["profilePicURL"] != null) {
          imageLink = ds.data["profilePicURL"];
        }
      });
    });
  }

  Widget buildProfileImage() {
    return Center(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(5.0),
          ),
          GestureDetector(
            onTap: getImageMenu,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageLink,
                width: 150.0,
                height: 150.0,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.black,
              size: 30.0,
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => EditProfilePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget buildFullName() {
    TextStyle nameTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black,
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
    );

    return AutoSizeText(
      fullName,
      style: nameTextStyle,
      maxLines: 1,
    );
  }

  Widget buildScoreBar(String label, String count) {
    TextStyle statLabelTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w200,
    );

    TextStyle statCountTextStyle = TextStyle(
      color: Colors.black54,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    );

    Size screenSize = MediaQuery.of(context).size;
    return InkWell(
        onTap: () {
          if (label == "Points") {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return rankInformationMessage(context);
                });
          } else if (label == "Followers") {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new FollowingFollowersPage(0);
            }));
          } else if (label == "Following") {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new FollowingFollowersPage(1);
            }));
          } else if (label == "Posts") {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return new MyPostPage();
            }));
          } else {
            print("Unknown Statbar button click");
          }
        },
        child: Container(
            width: screenSize.width / 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  count,
                  style: statCountTextStyle,
                ),
                Text(
                  label,
                  style: statLabelTextStyle,
                ),
              ],
            )));
  }

  Widget buildStatContainer() {
    return Container(
      height: 60.0,
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFFEFF4F7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildScoreBar("Followers", followers),
          buildScoreBar("Following", following),
          buildScoreBar("Posts", posts),
          buildScoreBar("Points", scores),
        ],
      ),
    );
  }

  Widget buildDate(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.bold, //try changing weight to w500 if not thin
      fontSize: 16.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      child: Text(
        "Member Since $dateJoined",
        textAlign: TextAlign.center,
        style: bioTextStyle,
      ),
    );
  }

  Widget buildBio(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w400, //try changing weight to w500 if not thin
      color: Color(0xFF799497),
      fontSize: 16.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      child: Text(
        bio,
        textAlign: TextAlign.center,
        style: bioTextStyle,
      ),
    );
  }

  Widget buildSeparator(Size screenSize) {
    return Container(
      width: screenSize.width / 1.6,
      height: 2.0,
      color: Colors.black54,
      margin: EdgeInsets.only(top: 4.0),
    );
  }

  Widget buildGetInTouch(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(top: 8.0),
      child: Text(
        "Get in Touch with ${fullName.split(" ")[0]},",
        style: TextStyle(fontFamily: 'Roboto', fontSize: 16.0),
      ),
    );
  }

  Widget buildJobTitle(BuildContext context) {
    if (title == null || title.length < 1) return Container();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Spectral',
          color: Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }



  Widget _buildIconTile(IconData icon, Color color, String title, String link) {
    //These selection for responding to onTap on each menu
    MaterialPageRoute route;
//    if (link == "profile") {
//      route = MaterialPageRoute(
//          builder: (BuildContext context) => EditProfilePage());
//    }
     if (link == "mypost") {
      route =
          MaterialPageRoute(builder: (BuildContext context) => MyPostPage());
    } else if (link == "favorite") {
      route =
          MaterialPageRoute(builder: (BuildContext context) => FavoritePage());
    } else if (link == "group") {
      route = MaterialPageRoute(builder: (BuildContext context) => GroupPage());
    } else if (link == "topic") {
      route = null;
    } else if (link == "follower") {
      route = MaterialPageRoute(
          builder: (BuildContext context) => FollowingFollowersPage(0));
    }
//    else if (link == "chat") {
//      route = MaterialPageRoute(
//          builder: (BuildContext context) => NewChatScreen(
//                currentUserId: CurrentUser.userID,
//              ));
//    }
    else if (link == "buyquestions") {
      route = MaterialPageRoute(
          builder: (BuildContext context) => BuyMoreQuestions());
    } else if (link == "aboutus") {
      route =
          MaterialPageRoute(builder: (BuildContext context) => AboutUsPage());
    } else if (link == "rateus") {
      route =
          MaterialPageRoute(builder: (BuildContext context) => ContactUsPage());
    } else if (link == "topbees") {
      route = MaterialPageRoute(
          builder: (BuildContext context) => LeaderboardPage());
    }

    //Building menu card container
    return GestureDetector(
      onTap: () => setState(() {
        name(route, link);
      }),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Container(
          height: 30.0,
          width: 30.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
        trailing: Icon(LineIcons.chevron_circle_right),
      ),
    );
  }

  //helper function to show topic selection dialog
  void name(MaterialPageRoute route, String link) {
    if (link == 'topic') {
      _showReportDialog();
    } else {
      Navigator.of(context).push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hr = Divider();

    final buildButtonList = Padding(
      padding: EdgeInsets.only(right: 20.0, left: 20.0, bottom: 30.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(8.0),
        shadowColor: Colors.white,
        child: Container(
          height: 432.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: <Widget>[
              _buildIconTile(
                  LineIcons.star, Colors.blue, 'Favorite Posts', 'favorite'),
              hr,
              _buildIconTile(LineIcons.tags, Colors.black, 'Topics', 'topic'),
              hr,
//              _buildIconTile(LineIcons.cog, Colors.black.withOpacity(0.6),
//                  'Help', 'profile'),
//              hr,
//              _buildIconTile(Icons.chat, Colors.black, 'Chats', 'chat'),
//              hr,
              _buildIconTile(Icons.card_giftcard, Colors.yellow,
                  'Buy More Questions', 'buyquestions'),
              hr,
              _buildIconTile(
                  LineIcons.info, Colors.black, 'About US', 'aboutus'),
              hr,
              _buildIconTile(
                  LineIcons.paper_plane, Colors.black, 'Rate US', 'rateus'),
              hr,
              _buildIconTile(
                  LineIcons.trophy, Colors.black, 'Top Bees', 'topbees'),
              hr,
            ],
          ),
        ),
      ),
    );
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text("Profile"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context, delegate: TestSearch(getSearchBarData()));
              },
            )
          ]),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: ListView(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    buildProfileImage(),
                    buildFullName(),
                    buildJobTitle(context),
                    buildRank(context),
                    buildStatContainer(),
                    buildDate(context),
                    buildBio(context),
                    buildSeparator(screenSize),
                    SizedBox(height: 10.0),
                    buildButtonList,
                    //buildAppButtonsList,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => postQuestion(null, null) //AddPost(),
                  ));
        },
        heroTag: "profileHeroe1",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 18,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, true),
    );
  }
}

class CachedCachedNetworkImageProvider {}

AlertDialog rankInformationMessage(BuildContext context) {
  String larvaeImageURL =
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/rankIcons%2FLarvae.png?alt=media&token=9afeb4c7-dbaf-4f8f-9885-3906155ed612";
  String workerBeeImageURL =
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/rankIcons%2Fbee.png?alt=media&token=80bd21e2-f795-46f4-a273-4d5653dfa414";
  String queenBeeImageURL =
      "https://firebasestorage.googleapis.com/v0/b/advicebee-9f277.appspot.com/o/rankIcons%2FqueenBee2.png?alt=media&token=c4b425ed-76c8-44fb-a933-5ca00031168b";

  return AlertDialog(
      title: Text(
        "Rank System",
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
          child: ListBody(children: <Widget>[
        Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            image: new DecorationImage(
              image: new CachedNetworkImageProvider(larvaeImageURL),
              //fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          "Larvae: 0-499 Points\n ",
          textAlign: TextAlign.center,
        ),
        Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            image: new DecorationImage(
              image: new CachedNetworkImageProvider(workerBeeImageURL),
              //fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          "Worker Bee: 500-999 Points\n",
          textAlign: TextAlign.center,
        ),
        Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            image: new DecorationImage(
              image: new CachedNetworkImageProvider(queenBeeImageURL),
              //fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          "Queen Bee: 1000+ Points\n",
          textAlign: TextAlign.center,
        ),
        Text(
          "You get up to 100 points per day when you open AdviceBee. Asking"
          " a question costs 10 points, while answering questions rewards you with 10 points. "
          "You gain 10 points per like on your answers.",
          textAlign: TextAlign.center,
        ),
        Container(
          width: 80,
          height: 50,
          child: GestureDetector(
            child: Text(
              "\nGood to know!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ),
      ])));
}

String getMonth(int month) {
  if (month == 1) {
    return "January ";
  } else if (month == 2) {
    return "February ";
  } else if (month == 3) {
    return "March ";
  } else if (month == 4) {
    return "April ";
  } else if (month == 5) {
    return "May ";
  } else if (month == 6) {
    return "June ";
  } else if (month == 7) {
    return "July ";
  } else if (month == 8) {
    return "August ";
  } else if (month == 9) {
    return "September ";
  } else if (month == 10) {
    return "October ";
  } else if (month == 11) {
    return "November ";
  } else if (month == 12) {
    return "December ";
  } else {
    return "$month ";
  }
}
