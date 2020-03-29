import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import './utils/validator.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'MoreMenu.dart';
import 'package:flutter/services.dart';
import 'ArcChooser.dart';
import 'SmilePainter.dart';

class ContactUsPage extends StatefulWidget {
  @override
  _MyReviewPageState createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<ContactUsPage>
    with TickerProviderStateMixin {
  int currentTab = 3;
  GlobalKey key = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = new TextEditingController();
  final TextEditingController _message = new TextEditingController();

  bool _autoValidate = false;


  final PageController pageControl = new PageController(
    initialPage: 2,
    keepPage: false,
    viewportFraction: 0.2,
  );

  int slideValue = 200;
  int lastAnimPosition = 2;

  AnimationController animation;

  List<ArcItem> arcItems = List<ArcItem>();

  ArcItem badArcItem;
  ArcItem ughArcItem;
  ArcItem okArcItem;
  ArcItem goodArcItem;

  Color startColor;
  Color endColor;

  @override
  void initState() {
    super.initState();

    badArcItem = ArcItem("BAD", [Color(0xFFfe0944), Color(0xFFfeae96)], 0.0);
    ughArcItem = ArcItem("UGH", [Color(0xFFF9D976), Color(0xfff39f86)], 0.0);
    okArcItem = ArcItem("OK", [Color(0xFF21e1fa), Color(0xff3bb8fd)], 0.0);
    goodArcItem = ArcItem("GOOD", [Color(0xFF3ee98a), Color(0xFF41f7c7)], 0.0);

    arcItems.add(badArcItem);
    arcItems.add(ughArcItem);
    arcItems.add(okArcItem);
    arcItems.add(goodArcItem);

    startColor = Color(0xFF21e1fa);
    endColor = Color(0xff3bb8fd);

    animation = new AnimationController(
      value: 0.0,
      lowerBound: 0.0,
      upperBound: 400.0,
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..addListener(() {
        setState(() {
          slideValue = animation.value.toInt();

          double ratio;

          if (slideValue <= 100) {
            ratio = animation.value / 100;
            startColor =
                Color.lerp(badArcItem.colors[0], ughArcItem.colors[0], ratio);
            endColor =
                Color.lerp(badArcItem.colors[1], ughArcItem.colors[1], ratio);
          } else if (slideValue <= 200) {
            ratio = (animation.value - 100) / 100;
            startColor =
                Color.lerp(ughArcItem.colors[0], okArcItem.colors[0], ratio);
            endColor =
                Color.lerp(ughArcItem.colors[1], okArcItem.colors[1], ratio);
          } else if (slideValue <= 300) {
            ratio = (animation.value - 200) / 100;
            startColor =
                Color.lerp(okArcItem.colors[0], goodArcItem.colors[0], ratio);
            endColor =
                Color.lerp(okArcItem.colors[1], goodArcItem.colors[1], ratio);
          } else if (slideValue <= 400) {
            ratio = (animation.value - 300) / 100;
            startColor =
                Color.lerp(goodArcItem.colors[0], badArcItem.colors[0], ratio);
            endColor =
                Color.lerp(goodArcItem.colors[1], badArcItem.colors[1], ratio);
          }
        });
      });

    animation.animateTo(slideValue.toDouble());
  }

  _showSubmitForm() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            contentPadding: EdgeInsets.only(top: 10.0),
            content: Container(
              width: 400.0,
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
                        "Send us your feedback!",
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
                        child: Form(
                          key: _formKey,
                          autovalidate: _autoValidate,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Material(
                                elevation: 8.0,
                                shadowColor: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                                child: TextFormField(
                                  controller: _name,
                                  validator: Validator.validateName,
                                  decoration: InputDecoration(
                                      icon: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.person,
                                            color: Color(0xff224597)),
                                      ),
                                      hintText: 'Your name',
                                      fillColor: Colors.white,
                                      filled: true,
                                      contentPadding: EdgeInsets.fromLTRB(
                                          10.0, 10.0, 20.0, 10.0),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          borderSide: BorderSide(
                                              color: Colors.white,
                                              width: 0.0))),
                                ),
                              ),
                              SizedBox(height: 5),
                              Material(
                                elevation: 8.0,
                                shadowColor: Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                                child: TextFormField(
                                  controller: _message,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 7,
                                  decoration: InputDecoration(
                                    hintText: 'Message',
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: EdgeInsets.fromLTRB(
                                        10.0, 10.0, 10.0, 10.0),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 0.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _mailOut(_name.text, _message.text);

                    },
                    child: Container(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32.0),
                            bottomRight: Radius.circular(32.0)),
                      ),
                      child: Text(
                        "Send Message",
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

  _showPositive() {
    Flushbar(
      title: "AdviceBee",
      message:
          "Thank you so much for your kind feedback, ${CurrentUser.displayName.split(" ")[0]}. "
          "We really appreciate you taking the time out to share your experience with us—",
      duration: Duration(seconds: 8),
      backgroundColor: Colors.teal,
    )..show(context);
  }

  _checkCurrentSelected(int value) {
    if (value <= 100) {
      _showSubmitForm();
    } else if (value <= 200) {
      _showPositive();
    } else if (value <= 300) {
      _showPositive();
    } else if (value <= 400) {
      _showSubmitForm();
    }
  }

  _mailOut(String email, String message) async {
    if (_formKey.currentState.validate()) {
      final MailOptions mailOptions = MailOptions(
        body: message == null? 'a long body for the email <br> with a subset of HTML': message,
        subject: 'Feedback from customer',
        recipients: ['wsuadvicebee@gmail.com'],
        isHTML: true,
      );

      await FlutterMailer.send(mailOptions);
      Flushbar(
        title: "Thanks for letting us know.",
        message:
        "Your feedback improves the quality of the app.",
        duration: Duration(seconds: 8),
        backgroundColor: Colors.teal,
      )..show(context);
      Navigator.pop(context);
    }
    else {
      setState(() => _autoValidate = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
    appBar: AppBar(
    title: Text("Rate Us"),
    centerTitle: true,
      leading:MaterialButton(
        key: key,
        minWidth: MediaQuery.of(context).size.width / 5,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(),
              )
          );
          if (CurrentUser.isNotGuest) {
          } else {
            guestUserSignInMessage(context);
          }
        },
        child: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 30,
        ),
      ),
    ),
      body: Container(
        margin: MediaQuery.of(context).padding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "How was your experience with us?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline,
                  ),
                ),
              ),
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width,
                    (MediaQuery.of(context).size.height / 2)-60),
                painter: SmilePainter(slideValue),
              ),
              Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: <Widget>[
                    ArcChooser()
                      ..arcSelectedCallback = (int pos, ArcItem item) {
                        int animPosition = pos - 2;
                        if (animPosition > 3) {
                          animPosition = animPosition - 4;
                        }

                        if (animPosition < 0) {
                          animPosition = 4 + animPosition;
                        }

                        if (lastAnimPosition == 3 && animPosition == 0) {
                          animation.animateTo(4 * 100.0);
                        } else if (lastAnimPosition == 0 && animPosition == 3) {
                          animation.forward(from: 4 * 100.0);
                          animation.animateTo(animPosition * 100.0);
                        } else if (lastAnimPosition == 0 && animPosition == 1) {
                          animation.forward(from: 0.0);
                          animation.animateTo(animPosition * 100.0);
                        } else {
                          animation.animateTo(animPosition * 100.0);
                        }

                        lastAnimPosition = animPosition;
                      },
                  ]),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.mail,
          size: 25.0,
        ),
        heroTag: "contactUsHero",
        onPressed: () {
          if(CurrentUser.isNotGuest)
            _checkCurrentSelected(animation.value.toInt());
          else
            guestUserSignInMessage(context);

        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
    );
  }
}
