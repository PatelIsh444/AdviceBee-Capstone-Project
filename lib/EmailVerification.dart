import 'Dashboard.dart';
import 'IntroSlider.dart';
import 'landing.dart';
import './services/AuthProvider.dart';
import './utils/messageHandler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flushbar/flushbar.dart';


class EmailVerification extends StatefulWidget {


  _EmailVerificationState createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  bool _UserVerified = false;

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    final pageTitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Hello there.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 45.0,
          ),
        ),
        Text(
          "A verification link has been sent to your email!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );

    final logo = Hero(
      tag: 'emailHero',
      child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 60.0,
          child: ClipOval(
            child: Image.asset(
              'images/logo.png',
              fit: BoxFit.cover,
              width: 120.0,
              height: 120.0,
            ),
          )),
    );

    final confirmEmailButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: () {
          _confirmEmail(context: context);
        },
        padding: EdgeInsets.all(12),
        color: Theme.of(context).primaryColor,
        child: Text('CONFIRM EMAIL', style: TextStyle(color: Colors.white)),
      ),
    );

    final continueButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IntroSlider(),
              ));
        },
        padding: EdgeInsets.all(12),
        color: Theme.of(context).primaryColor,
        child: Text("Sign Me In", style: TextStyle(color: Colors.white)),
      ),
    );


    //If the user doesn't want to continue to verify the email
    //They can logout and the app takes them back to the login page
    final signOutLabel = FlatButton(
      child: Text(
        'Sign Out',
        style: TextStyle(color: Colors.black54),
      ),
      onPressed: () {
        final auth = AuthProvider.of(context);

        try {
          auth.SignOut();
          Navigator.pushReplacementNamed(context, MyApp.id);
          Navigator.of(context).pushNamedAndRemoveUntil(MyApp.id, (Route<dynamic> route) => false);

        } catch (e) {
          print(e.toString());
        }
      },
    );

    Widget swapWidget;
    if (_UserVerified) {
      swapWidget = continueButton;
    } else {
      swapWidget = confirmEmailButton;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  pageTitle,
                  logo,
                  SizedBox(height: 48.0),
                  swapWidget,
                  signOutLabel,

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }




  void _confirmEmail({BuildContext context}) async {
    //Open issue on GitHub support group
    //Double call currentUser() to get an update on current user's state
    //to check if they have verified their email.
    String message = "";
    try {
      FirebaseUser user = await FirebaseAuth.instance.currentUser();
      await user.reload();
      user = await FirebaseAuth.instance.currentUser();

      if (user.isEmailVerified) {
        //User is verified then show Continue Button
        setState(() {
          _UserVerified = true;
        });
        message = "Welcome Aboard, please click Continue to start!";
      }
      else{
        message = "Please check your inbox...";
      }

      Flushbar(
        title: "Almost there...",
        message:message,
        duration: Duration(seconds: 5),
        backgroundColor: Colors.teal,
      )..show(context);

    } catch (e) {
      String exception = messageHandler.getExceptionText(e);
      Flushbar(
        title: "Verification Password Error",
        message: exception,
        duration: Duration(seconds: 10),
      )..show(context);
    }
  }
}
