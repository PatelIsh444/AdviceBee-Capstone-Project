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

void main() => runApp(Advicebee());

class Advicebee extends StatelessWidget {
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
