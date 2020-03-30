import 'package:firebase_auth/firebase_auth.dart';

import 'Dashboard.dart';
import 'EmailVerification.dart';
import 'landing.dart';
import './services/AuthProvider.dart';
import './services/auth.dart';
import 'package:flutter/material.dart';
import './utils/commonFunctions.dart';



class ActMainApp extends StatelessWidget {

  static String id = 'actmain';


  //Using streambuilder, on user's authentication state change
  //Redirect the user to Dashboard if they logged in
  //Redirect to initial screen of they logged out
  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.of(context);
    return StreamBuilder<User>(
      stream: auth.onAuthStateChanged,
      builder: (context,snapshot) {
        if(snapshot.connectionState == ConnectionState.active){
          User user = snapshot.data;

          if (user == null ) {
            return MyApp();
          }

          if(!user.emailVerified){
            if(CurrentUser!=null && CurrentUser.isNotGuest){
              return EmailVerification();
            }
          }

          //Update a users points when they first open the app.
          checkDailyPoints();

          return Dashboard();


        }
        else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    );

  }
}