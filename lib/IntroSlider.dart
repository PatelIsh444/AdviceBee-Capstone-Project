
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:v0/main.dart';
import 'package:v0/utils/commonFunctions.dart';
import 'Dashboard.dart';
import 'ForgotPassword.dart';
import 'NewLogin.dart';
import 'Notification.dart';
import 'PickTopics.dart';
import 'SignUp.dart';
import 'User.dart';
import 'actmain.dart';
import 'landing.dart';

class IntroSlider extends StatefulWidget{
  @override
  IntroSliderState createState() => IntroSliderState();
}

class IntroSliderState extends State<IntroSlider>with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');

    if (state == AppLifecycleState.resumed) {
      print('state = $state');
      setUserOnline();
    } else {
      print('state = $state');
      setUserLastAccess();
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setUserLastAccess();
    super.dispose();
  }

  final pages = [
    PageViewModel(
      pageColor: const Color(0XFFAFD6A7),
      //bubble: Image.asset('assets/newlogo.png'),
      body: Text(
        'Dr. Seyed Ziae Mousavi Mojab,\n'
            'Is a Co-founder of this software, he has a great vision to help students in solving their problems in all type of field by connecting them to best experts in all field through a software.\n'
            'ADVICEBEE CAN DO THIS!',
      ),
      title: Text('WelCome',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 40.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,),),
      textStyle: TextStyle(fontSize: 17.0,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: Colors.black,),
      mainImage: Image.asset(
        'images/logoTeal.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      ),
    ),
    PageViewModel(
      pageColor: const Color(0xff9fa8da),
      body: Text(
        'Welcome to AdviceBee,\n'
            ' A leading Advice getting Softwere.'
            'AdviceBee is designed for the students of Wayne State University'
            'This Software will help students to solve their difficulties in any subject'
            'by connecting best experts to the students.',
      ),
      title: Text('Advice Bee',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 40.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,),),
      textStyle: TextStyle(fontSize: 17.0,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: Colors.black,),
      mainImage: Image.asset(
        'images/logoTeal.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      ),
    ),
    PageViewModel(
      pageColor: const Color(0xff80cbc4),


      title: Text(
        "Rank System",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 40.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,),
      ),
      body: Text(
          "Larvae: 0-499 Points\n"
              "Worker Bee: 500-999 Points\n"
              "Queen Bee: 1000+ Points\n"
              "You get 100 points per day when you open AdviceBee. Asking "
              "a question costs 10 points, while answering questions and, recieving each likes "
              "reward 10 points."
      ),
      textStyle: TextStyle(fontSize: 17.0,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: Colors.black,),
      mainImage: Image.asset(
        'images/logoTeal.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      ),

    )
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(
        builder: (context) =>
            IntroViewsFlutter(
                pages,
                onTapDoneButton: () {
                  Colors.black;
                  Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => Dashboard(),
                      ));
                },
                pageButtonTextStyles: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                )
            ),
      ),
    );
  }
}