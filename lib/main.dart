import 'package:v0/IntroSlider.dart';
import 'package:v0/OtherUserFollowerPage.dart';

import 'Dashboard.dart';
import 'ForgotPassword.dart';
import 'NewLogin.dart';
import 'Notification.dart';
import 'PickTopics.dart';
import 'actmain.dart';
import 'landing.dart';
import './services/AuthProvider.dart';
import './services/auth.dart';
import 'SignUp.dart';
import 'package:flutter/material.dart';
import './utils/commonFunctions.dart';

void main() => runApp(Advicebee());

class Advicebee extends StatefulWidget{

  @override
  AdvicebeeState createState() => AdvicebeeState();
}
class AdvicebeeState extends State<Advicebee> with WidgetsBindingObserver {

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
    if (CurrentUser.isNotGuest) {
      if (state == AppLifecycleState.resumed) {
        print('state = $state');
        setUserOnline();
      } else {
        print('state = $state');
        setUserLastAccess();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setUserLastAccess();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AuthProvider(
      auth: Auth(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch: Colors.teal
        ),
        initialRoute: ActMainApp.id ,
        routes: {
          ActMainApp.id: (context) => ActMainApp(),
          SignUpScreen.id: (context) => SignUpScreen(),
          MyApp.id:(context) => MyApp(),
          SignInScreen.id:(context) => SignInScreen(),
          ForgotPasswordScreen.id:(context) => ForgotPasswordScreen(),
          Dashboard.id:(context) => Dashboard(),
          PickTopic.id:(context) => PickTopic(),
          NotificationFeed.id:(context) => NotificationFeed(),
        },
      ),
    );
  }
}
