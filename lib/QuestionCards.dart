import 'dart:async';
import 'User.dart';
import 'newProfile.dart';
import './utils/commonFunctions.dart';
import 'package:animator/animator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'QuestionPage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'Dashboard.dart';
import 'Profile.dart';
import './utils/dialogBox.dart';

const Color gradientStart = const Color(0xFFfbab66);
const Color gradientEnd = const Color(0xFFf7418c);

final chatBubbleGradient = const LinearGradient(
  colors: const [Color(0xFFFD60A3), Color(0xFFFF8961)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);
final primaryGradient = const LinearGradient(
  colors: const [gradientStart, gradientEnd],
  stops: const [0.0, 1.0],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

//integration to new query system
//target: Like and Favorite
final topicRef = Firestore.instance.collection('topics');
final groupPostRef = Firestore.instance.collection('groups');
final reportRef = Firestore.instance.collection('reports');

class QuestionCards extends StatefulWidget {
  //Variables
  User CurrentUser;
  String groupID;
  bool isLiked;
  List<questions> postList;
  String groups_or_topics;
  QuestionCards(this.CurrentUser, this.groupID, this.postList, this.isLiked,
      this.groups_or_topics);

  @override
  _QuestionCardsState createState() => _QuestionCardsState(PostSource: isLiked);
}

class _QuestionCardsState extends State<QuestionCards> {
  _QuestionCardsState({this.PostSource});

  String defaultPhoto = "https://firebasestorage.googleapis.com/v0/b/advicebee"
      "-9f277.appspot.com/o/noPictureThumbnail.png?alt=media&token=b7189670-"
      "8770-4f85-a51d-936a39b597a1";

  final bool PostSource;
  var thumbnailURLS = new List();

  @override
  void initState() {
    super.initState();
  }

  List<String> reportList = [
    "Illegal",
    "Spam",
    "Offensive",
    "Uncivil",
    "Not relevant",
  ];

  var databaseInstance = Firestore.instance.collection('posts');

  List<String> selectedReportList = List();

  //List variable to hold the current list of favorite posts
  var TempfavoritePosts = CurrentUser.isNotGuest
      ? new List<dynamic>.from(CurrentUser.favoritePosts)
      : new List();

  BuildContext context;
  final activityFeedRef = Firestore.instance.collection('Notification');
  DateTime get timestamp => DateTime.now();

  Container notAnswered() {
    return Container(
      height: 15.0,
      //width: 80.0,
      child: AutoSizeText(
        "Not Answered ",
        style: TextStyle(
            fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /*
    This two functions is designed for handle reporting function
    _handleReport will send a report to Firebase
     */
    _handleReport(String currentUserId, int index, BuildContext context,
        bool postSource) async {
      if (selectedReportList != null && selectedReportList.isNotEmpty) {
        await handleReport(currentUserId, index, context, postSource);
        selectedReportList =  null;
        Navigator.pop(context);
      } else
        Navigator.pop(context);
    }
     /*
     Show the dialog box for reporting
      */
    _showReportDialog(String currentUserId, int index, BuildContext context,
        bool postSource) {
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
                            "Report this Post ",
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
                        child: MultiSelectChip(
                          "report",
                          reportList,
                          onSelectionChanged: (selectedList) {
                            setState(() {
                              selectedReportList = selectedList;
                            });
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () => _handleReport(
                            CurrentUser.userID, index, context, widget.isLiked),
                        child: Container(
                          padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32.0),
                                bottomRight: Radius.circular(32.0)),
                          ),
                          child: Text(
                            "Report",
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                            textAlign: TextAlign.center,
                          ),
                        ),
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


    /*
    Function used to Undo Reporting
    Ask for confirmation
     */
    _showConfirmReportDialog(String currentUserId, int index, BuildContext context,
        bool postSource) {
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
                            "Undo Reporting",
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
                                "Cancel",
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
                              await handleReport(
                                CurrentUser.userID,
                                index,
                                context,
                                widget.isLiked);
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
                                "Undo",
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


    /*
    Question Card styling:
    Any modifications shall be within this Expanded
     */
    return Expanded(
        child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 2.0, color: Colors.black),
             //   left: BorderSide(width: 2.0, color: Colors.black),
             //   right: BorderSide(width: 2.0, color: Colors.black),
               // bottom: BorderSide(width: 2.0, color: Colors.black),
              ),
            ),
            height: 150.0,
            child: ListView.builder(
              addAutomaticKeepAlives: true,
              cacheExtent: 10,
              physics: const AlwaysScrollableScrollPhysics(),
                itemCount: widget.postList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          print(widget.postList[index].questionType);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return new PostPage(
                                widget.postList[index],
                                widget.groups_or_topics == "topics"
                                    ? widget.postList[index].topic
                                    : widget.groupID,
                                widget.postList[index].postID,
                                widget.groups_or_topics);
                          }));
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          child: Card(
                            key: Key(widget.postList[index].postID),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 3, bottom: 2.0, right: 8, left: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0.0, 0.0, 0.0, 1.0),
                                        //navigate user to the post page
                                        child: InkWell(
                                          onTap: () {
                                            print(widget
                                                .postList[index].questionType);
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (context) {
                                                      return new PostPage(
                                                          widget.postList[index],
                                                          widget.groups_or_topics ==
                                                              "topics"
                                                              ? widget
                                                              .postList[index].topic
                                                              : widget.groupID,
                                                          widget.postList[index].postID,
                                                          widget.groups_or_topics);
                                                    }));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Flexible(
                                                child: Text(
                                                  widget
                                                      .postList[index].question,
                                                  style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      fontSize: 18.0),
                                                ),
                                                flex: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      //Post Tile and Description
                                      SizedBox(height: 4,),
                                      Row(
                                        children: <Widget>[
                                          InkWell(
                                            onTap: () {
                                              if (widget
                                                  .postList[index].anonymous) {
                                                Flushbar(
                                                  message:
                                                      "This user is anonymous, you can not view their page.",
                                                  duration:
                                                      Duration(seconds: 5),
                                                  backgroundColor: Colors.teal,
                                                )..show(context);
                                              } else {
                                                if (widget.CurrentUser.userID ==
                                                    widget.postList[index]
                                                        .createdBy) {
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (BuildContext
                                                                  context) =>
                                                              ProfilePage()));
                                                } else {
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) {
                                                    return new UserDetailsPage(
                                                      widget.postList[index]
                                                          .createdBy,
                                                    );
                                                  }));
                                                }
                                              }
                                            },
                                            child: CircleAvatar(
                                              backgroundImage: CachedNetworkImageProvider(
                                                  widget.postList[index]
                                                              .thumbnailURL ==
                                                          null
                                                      ? defaultPhoto
                                                      : widget.postList[index]
                                                          .thumbnailURL),
                                              minRadius: 22,
                                              maxRadius: 22,
                                            ),
                                          ),
                                          Stack(children: <Widget>[
                                            widget.groups_or_topics == "topics"
                                                ? Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4, top: 21),
                                                    child: Container(
                                                        width: 200,
                                                        child: AutoSizeText(
                                                          "Posted to " +
                                                              widget
                                                                  .postList[
                                                                      index]
                                                                  .topic +
                                                              " " +
                                                              timeago.format(
                                                                  widget
                                                                      .postList[
                                                                          index]
                                                                      .datePosted
                                                                      .toDate()),
                                                          style: TextStyle(
                                                              fontSize: 16.0),
                                                          maxLines: 1,
                                                        )),
                                                  )
                                                : Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4, top: 21),
                                                    child: Container(
                                                      width: 200,
                                                      child: AutoSizeText(
                                                        "Posted " +
                                                            timeago.format(
                                                                widget
                                                                    .postList[
                                                                        index]
                                                                    .datePosted
                                                                    .toDate()),
                                                        style: TextStyle(
                                                            fontSize: 16.0),
                                                      ),
                                                    ),
                                                  ),
                                            GestureDetector(
                                              onTap: () {
                                                //Start of merge branch

                                                if (widget.postList[index]
                                                    .anonymous) {
                                                  Flushbar(
                                                    message:
                                                        "This user is anonymous, you can not view their page.",
                                                    duration:
                                                        Duration(seconds: 5),
                                                    backgroundColor:
                                                        Colors.teal,
                                                  )..show(context);
                                                } else {
                                                  if (widget
                                                          .CurrentUser.userID ==
                                                      widget.postList[index]
                                                          .createdBy) {
                                                    Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                            builder: (BuildContext
                                                                    context) =>
                                                                ProfilePage()));
                                                  } else {
                                                    Navigator.push(context,
                                                        MaterialPageRoute(
                                                            builder: (context) {
                                                      return new UserDetailsPage(
                                                        widget.postList[index]
                                                            .createdBy,
                                                      );
                                                    }));
                                                  }
                                                  //End of merge branch

                                                }
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 4, bottom: 23),
                                                child: Container(
                                                  width: widget.postList[index].userDisplayName.length* 10.0,
                                                  child: AutoSizeText(
                                                    widget.postList[index]
                                                                .anonymous ==
                                                            true
                                                        ? "Anonymous"
                                                        : widget.postList[index]
                                                            .userDisplayName,
                                                    style: TextStyle(
                                                        fontSize: 16.0,
                                                        ),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ),


                                      SizedBox(
                                        height: 2,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Container(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    ![null, 0].contains(widget
                                                            .postList[index]
                                                            .numOfResponses)
                                                        ? Container()
                                                        : notAnswered(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          //Like and Favorite button
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              //Answer Icon
                                              //Using Stack to show Notification Badge
                                              new Stack(
                                                children: <Widget>[
                                                  Container(
                                                      width: 46,
                                                      height: 31,
                                                      child: new Icon(
                                                        Icons.question_answer,
                                                        size: 20,

                                                        //Color(0xFFCBD7D0),
                                                        color: Colors.green

                                                        //Colors.grey,
                                                      )),
                                                  new Positioned(
                                                    left: 30,
                                                    bottom: 15,
                                                    child: new Container(
                                                      padding: EdgeInsets.only(
                                                          left: 1.0,
                                                          right: 1.0),
                                                      decoration:
                                                          new BoxDecoration(
                                                        //color: Color(0xFFFD60A3),
                                                        border: Border.all(
                                                            color: Colors
                                                                .transparent),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                      ),
                                                      constraints:
                                                          BoxConstraints(
                                                        minWidth: 14,
                                                        minHeight: 14,
                                                      ),
                                                      child: AutoSizeText(
                                                        "${[
                                                          null,
                                                          0
                                                        ].contains(widget.postList[index].numOfResponses) ? "0" : "${widget.postList[index].numOfResponses}"} ",
                                                        style:
                                                        TextStyle(
                                                          color: Colors.black,
//                                                          fontWeight:
//                                                              FontWeight.bold,
                                                          fontSize:5,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              //View Icon
                                              //Using Stack to show Notification Badge
                                              new Stack(
                                                children: <Widget>[
                                                  Container(
                                                      width: 46,
                                                      height: 31,
                                                      child: new Icon(
                                                        Icons.remove_red_eye,
                                                        size: 20,
                                                        color:
                                                        //Color(0xFFE9A215),
                                                        Colors.green,
                                                      )),
                                                  new Positioned(
                                                    left: 30,
                                                    bottom: 15,
                                                    child: new Container(
                                                      padding: EdgeInsets.only(
                                                          left: 1.0,
                                                          right: 1.0),
                                                      decoration:
                                                          new BoxDecoration(
                                                        //color: Color(0xFFFD60A3),
                                                        border: Border.all(
                                                            color: Colors
                                                                .transparent),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                      ),
                                                      constraints:
                                                          BoxConstraints(
                                                        minWidth: 14,
                                                        minHeight: 14,
                                                      ),
                                                      child: AutoSizeText(
                                                        "${widget.postList[index].views != null ? widget.postList[index].views.length : 0}",
                                                        style: TextStyle(
                                                          color: Colors.black,
//                                                          fontWeight:
//                                                              FontWeight.bold,
                                                          fontSize: 5,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              //Like icon (Heart)
                                              InkWell(
                                                onTap: () => handleLike(
                                                    CurrentUser.userID,
                                                    index,
                                                    context,
                                                    widget.isLiked),
                                                child: CurrentUser.isNotGuest &&
                                                        getLikeCount(widget
                                                                .postList[index]
                                                                .likes) !=
                                                            -1
                                                    ?
                                                    //Using Stack to show Notification Badge
                                                    new Stack(
                                                        children: <Widget>[
                                                          Container(
                                                              width: 46,
                                                              height: 31,
                                                              child: new Icon(
                                                                widget.postList[index].likes[CurrentUser
                                                                            .userID] ==
                                                                        true
                                                                    ? Icons
                                                                        .favorite
                                                                    : Icons
                                                                        .favorite_border,
                                                                size: 20,
                                                                color: Colors.green,
                                                                //Colors.teal,
                                                                //Color(0xFFB83330),
                                                              )),
                                                          getLikeCount(widget
                                                                      .postList[
                                                                          index]
                                                                      .likes) !=
                                                                  -1
                                                              ? new Positioned(
                                                                  left: 30,
                                                                  bottom: 15,
                                                                  child:
                                                                      new Container(
                                                                    padding: EdgeInsets.only(
                                                                        left:
                                                                            1.0,
                                                                        right:
                                                                            1.0),
                                                                    decoration:
                                                                        new BoxDecoration(
                                                                      //color: Color(0xFFFD60A3),
                                                                      border: Border.all(
                                                                          color:
                                                                          //Color(0xFFB83330)
                                                                        Colors.transparent,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              100),
                                                                    ),
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      minWidth:
                                                                          14,
                                                                      minHeight:
                                                                          14,
                                                                    ),
                                                                    child:
                                                                        AutoSizeText(
                                                                      "${getLikeCount(widget.postList[index].likes)}",
                                                                      style:
                                                                          TextStyle(
                                                                        color:
                                                                        Colors.black,
                                                                        //Colors.teal,
                                                                        //Color(0xFFB83330),
//                                                                        fontWeight:
//                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            5,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                )
                                                              : new Container()
                                                        ],
                                                      )


                                                : Container(
                                                        width: 46,
                                                        height: 31,
                                                  child: Icon(
                                                          Icons.favorite_border,
                                                          size: 24,
                                                         // color: Colors.black
                                                          color: Colors.green,
                                                          //Colors.teal,

                                                              //Color(0xFFB83330),
                                                        ),
                                                      ),
                                              ),
                                              //Favorite icon (Star)
                                              InkWell(
                                                onTap: () => CurrentUser
                                                        .isNotGuest
                                                    ? handleFavorite(
                                                        CurrentUser.userID,
                                                        index,
                                                        context,
                                                        widget.isLiked)
                                                    : guestUserSignInMessage(
                                                        context),
                                                child: Container(
                                                  width: 46,
                                                  height: 31,
                                                  child: CurrentUser.isNotGuest
                                                      ? Icon(
                                                          checkCurrentFavorite(
                                                                  index,
                                                                  widget
                                                                      .isLiked)
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                          size: 24.0,
                                                          color: Colors.green,
                                                        //  color: Color(0xFFCBD7D0),
                                                          //color:Color(0xFFD5B690),
                                                          //Colors.amber,
                                                        )
                                                      : Icon(
                                                          Icons.star_border,
                                                          size: 24.0,
                                                          color: Colors.green,
                                                          //color: Color(0xFFCBD7D0),
                                                          //Color(0xFFD5B690),
                                                          //Colors.amber,
                                                        ),
                                                ),
                                              ),
                                              //Report icon (Exclamation mark)
                                              InkWell(
                                                onTap: () => widget
                                                                .postList[index]
                                                                .reports[
                                                            CurrentUser
                                                                .userID] ==
                                                        true
                                                    ? _showConfirmReportDialog(
                                                        CurrentUser.userID,
                                                        index,
                                                        context,
                                                        widget.isLiked)
                                                    : _showReportDialog(
                                                        CurrentUser.userID,
                                                        index,
                                                        context,
                                                        widget.isLiked),
                                                child: Container(
                                                  width: 46,
                                                  height: 31,
                                                  child: CurrentUser.isNotGuest
                                                      ? Icon(
                                                          widget.postList[index]
                                                                          .reports[
                                                                      CurrentUser
                                                                          .userID] ==
                                                                  true
                                                              ? Icons.error
                                                              : Icons
                                                                  .error_outline,
                                                          size: 22,
                                                          //color: Color(0xFFE9A215),0xFF004369
                                                          //color: Color(0xFFCBD7D0),
                                                    color: Colors.green,
                                                          //Color(0xFFCBD7D0),
                                                        )
                                                      : Container(
                                                          child: Icon(
                                                            Icons.error_outline,
                                                            size: 22,
                                                            //color: Colors.black,
                                                            //Color(0xFFCBD7D0),
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                //These two icons is for pop up animation
                                widget.postList[index].heart
                                    ? Animator(
                                        duration: Duration(milliseconds: 1000),
                                        tween: Tween(begin: 0.8, end: 1.4),
                                        curve: Curves.easeOut,
                                        cycles: 0,
                                        builder: (anim) => Transform.scale(
                                          scale: anim.value,
                                          child: Icon(
                                            Icons.favorite,
                                            size: 20.0,
                                           // color: Colors.black,
                                            color: Color(0xFFE9A215),
                                          ),
                                        ),
                                      )
                                    : Text(""),
                                widget.postList[index].star
                                    ? Animator(
                                        duration: Duration(milliseconds: 1000),
                                        tween: Tween(begin: 0.8, end: 1.4),
                                        curve: Curves.easeOut,
                                        cycles: 0,
                                        builder: (anim) => Transform.scale(
                                          scale: anim.value,
                                          child: Icon(Icons.star,
                                              size: 20.0,
                                            color: Color(0xFFE9A215),
                                             // color: Color(0xFFCBD7D0),
                                          ),
                                        ),
                                      )
                                    : Text(""),
                              ],
                            ),
                          ),
                        ),
                      ),
                      index == widget.postList.length - 1
                          ? SizedBox(
                              height: 130,
                            )
                          : Container(),
                    ],
                  );
                })));
  }

  //This function update the star status for favorite function
  //Filled star means the post is in the favorite list
  //Split and get the last item as Post ID
  bool checkCurrentFavorite(int index, bool PostSource) {
    bool flag;
    if (CurrentUser.favoritePosts.isEmpty) {
      flag = false;
    }
    for (DocumentReference post in CurrentUser.favoritePosts) {
      var referencePathSplit = post.path.split("/");
      if (referencePathSplit[3] == widget.postList[index].postID) {
        flag = true;
        break;
      }
      flag = false;
    }
    return flag;
  }

  String setResponses(int numOfResponses) {
    if (numOfResponses > 1)
      return " responses";
    else
      return " response";
  }

  //Handle favorite logic
  //Write to firebase the path for the post
  handleFavorite(
      String currentUserId, int index, BuildContext context, bool postSource) {
    print("Handle Favorite");
    DocumentReference PostRoute;
    postSource
        ? PostRoute = topicsRef
            .document(widget.postList[index].topic)
            .collection('topicQuestions')
            .document(widget.postList[index].postID)
        : PostRoute = groupPostRef
            .document(widget.groupID)
            .collection("groupQuestions")
            .document(widget.postList[index].postID);

    if (CurrentUser.isNotGuest) {
      bool _isFavorited = checkCurrentFavorite(index, postSource);

      if (_isFavorited) {
        print("Remove Favorite");

        setState(() {
          checkCurrentFavorite(index, postSource);
          widget.postList[index].star = false;

          usersRef.document(CurrentUser.userID).updateData({
            'favoritePosts': FieldValue.arrayRemove([PostRoute]),
          });

          for (DocumentReference post in CurrentUser.favoritePosts) {
            var referencePathSplit = post.path.split("/");
            if (referencePathSplit[3] == widget.postList[index].postID) {
              TempfavoritePosts.remove(post);
              break;
            }
          }
        });
      } else if (!_isFavorited) {
        TempfavoritePosts.add(PostRoute);
        print("Favorited");

        //Update state after fisnish
        setState(() {
          usersRef.document(CurrentUser.userID).updateData({
            'favoritePosts': FieldValue.arrayUnion([PostRoute]),
          });
          checkCurrentFavorite(index, postSource);
          widget.postList[index].star = true;
        });

        Timer(Duration(milliseconds: 800), () {
          setState(() {
            widget.postList[index].star = false;
          });
        });
      }
      print(TempfavoritePosts);
      CurrentUser.favoritePosts = TempfavoritePosts;
      print("##################");
      print(CurrentUser.favoritePosts);
    } else {
      guestUserSignInMessage(context);
    }
  }

  //Function to get number of likes for each post
  int getLikeCount(Map likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  //This function use to update the state for like function
  //Await for firebase execution to finish and the update the state
  Future<void> updateLike(
      int index, String currentUserId, bool value, String postSource) async {
    if (postSource == "Group") {
      await groupPostRef
          .document(widget.groupID)
          .collection("groupQuestions")
          .document(widget.postList[index].postID)
          .updateData({'likes.$currentUserId': value});
    } else {
      await topicsRef
          .document(widget.postList[index].topic)
          .collection('topicQuestions')
          .document(widget.postList[index].postID)
          .updateData({'likes.$currentUserId': value});
    }
    //Update state after fisnish
    setState(() {
      widget.postList[index].likes[currentUserId] = value;
      widget.postList[index].heart = value;
    });
  }

  //Handle Like: postSource to determine the source for the post
  //if it from group: pass in new path for the firebase
  handleLike(
      String currentUserId, int index, BuildContext context, bool postSource) {
    print("Handle Like");
    if (CurrentUser.isNotGuest) {
      if (CurrentUser.userID == widget.postList[index].createdBy){
        userCantLikeTheirPostMessage(context);
      } else {
        bool _isLiked = widget.postList[index].likes[currentUserId] == true;
        if (_isLiked) {
          print("Unliked");
          //If post from group it will provide different path for the post
          if (!postSource) {
            print("Post from Group");
            updateLike(index, currentUserId, false, "Group");
            //Post from dashboard call
          } else {
            updateLike(index, currentUserId, false, "Dashboard");
          }
          RemoveLikeToNotification(index);
        } else if (!_isLiked) {
          print("Liked");

          if (!postSource) {
            print("Post from Group");
            updateLike(index, currentUserId, true, "Group");
          } else {
            print("Post from dashboard");
            updateLike(index, currentUserId, true, "Dashboard");
          }
          AddLikeToNotification(index);

          Timer(Duration(milliseconds: 800), () {
            setState(() {
              widget.postList[index].heart = false;
            });
          });
        }
      }
    } else {
      guestUserSignInMessage(context);
    }
  }

  void AddLikeToNotification(int index) {
    // add a notification to the postOwner's activity feed

    bool isNotPostOwner =
        CurrentUser.userID != widget.postList[index].createdBy;

    if (isNotPostOwner) {
      // if (isNotPostOwner ) {
      print(widget.CurrentUser.displayName);
      activityFeedRef
          .document(widget.postList[index].createdBy)
          .collection("NotificationItems")
          .document(widget.postList[index].postID)
          .setData({
        "type": "like",
        "username": widget.CurrentUser.displayName,
        "userId": widget.CurrentUser.userID,
        "userProfileImg": widget.CurrentUser.profilePicURL,
        "postId": widget.postList[index].postID,
        "timestamp": timestamp,
        "groups_or_topics": widget.groups_or_topics,
        "groupOrTopicID": widget.groups_or_topics == "topics"
            ? widget.postList[index].topic
            : widget.groupID,
      });

      print("Added Like to Notificaiton");
    }
  }

  void RemoveLikeToNotification(int index) {
    // add a notification to the postOwner's activity feed
    bool isNotPostOwner =
        CurrentUser.userID != widget.postList[index].createdBy;
    if (isNotPostOwner) {
      // if (isNotPostOwner ) {
      print(widget.CurrentUser.displayName);
      activityFeedRef
          .document(widget.postList[index].createdBy)
          .collection("NotificationItems")
          .document(widget.postList[index].postID)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });

      print("Removed Like from Notificaiton");
    }
  }

  //This function use to update the state for like function
  //Await for firebase execution to finish and the update the state
  Future<void> updateReport(
      int index, String currentUserId, bool value, String postSource) async {
    if (postSource == "Group") {
      await groupPostRef
          .document(widget.groupID)
          .collection("groupQuestions")
          .document(widget.postList[index].postID)
          .updateData({'reports.$currentUserId': value});
    } else {
      await topicsRef
          .document(widget.postList[index].topic)
          .collection('topicQuestions')
          .document(widget.postList[index].postID)
          .updateData({'reports.$currentUserId': value});
    }
    //Update state after fisnish
    setState(() {
      widget.postList[index].reports[currentUserId] = value;
    });
  }

  //Handle Like: postSource to determine the source for the post
  //if it from group: pass in new path for the firebase
  handleReport(
      String currentUserId, int index, BuildContext context, bool postSource) {
    print("Handle report");
    if (CurrentUser.isNotGuest) {
      bool _isreported = widget.postList[index].reports[currentUserId] == true;
      if (_isreported) {
        print("Remove report");
        //If post from group it will provide different path for the post
        if (!postSource) {
          print("Post from Group");
          updateReport(index, currentUserId, false, "Group");
          //Post from dashboard call
        } else {
          updateReport(index, currentUserId, false, "Dashboard");
        }
        RemovePostFromReport(index);
      } else if (!_isreported) {
        print("Liked");

        if (!postSource) {
          print("Post from Group");
          updateReport(index, currentUserId, true, "Group");
        } else {
          print("Post from dashboard");
          updateReport(index, currentUserId, true, "Dashboard");
        }
        AddPostToReport(index);
      }
    } else {
      guestUserSignInMessage(context);
    }
  }

  void AddPostToReport(int index) async{
    questions post = widget.postList[index];
    DocumentReference reportedPostRef = reportRef.document(post.postID);

    reportedPostRef.setData({
      "postId": post.postID,
      "postTitle": post.question,
      "postCreatedBy": post.createdBy,
      "postLocation": widget.groups_or_topics,
      "postLocationId": widget.groups_or_topics == "topics" ? post.topic : widget.groupID,
    });
    
    reportedPostRef.collection("ReportedUsers").document(CurrentUser.userID).setData({
      "reportedPostId": post.postID,
      "reasons": selectedReportList,
      "reportedBy": widget.CurrentUser.userID,
      "userDisplayName": widget.CurrentUser.displayName,
      "userProfileImg": widget.CurrentUser.profilePicURL,
      "dateReported": timestamp,
    });

    print("Added post to Report");
  }

  void RemovePostFromReport(int index) {
    // remove a post from the Report's list
    reportRef
        .document(widget.postList[index].postID)
        .collection("ReportedUsers")
        .document(CurrentUser.userID)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    print("Removed post from Report");
  }
}
