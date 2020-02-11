import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:meta/meta.dart';

final DateTime timestamp = DateTime.now();

class User {
  User({@required this.uid});
  final String uid;

}

abstract class AuthBase {
  Stream<User> get onAuthStateChanged;
  Future<User> currentUser();
  Future<User> signInWithGoogle(BuildContext context);
  Future<User> signInAnonymously();
  Future<User> signInWithFacebook();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<void> signUp(String name, String email, String password);
  Future<void> resetPassword(String email);
  Future<void> SignOut();
}

class Auth implements AuthBase {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final usersRef = Firestore.instance.collection('users');



  User _userFromFirebase(FirebaseUser user) {
    if (user == null) {
      return null;
    }

    return User(uid: user.uid);
  }

  //Stream get called by actmain.dart
  //To track user's changes on authentication
  //such as logged in or logged out
  Stream<User> get onAuthStateChanged {
    return _firebaseAuth.onAuthStateChanged.map(_userFromFirebase);
  }

  Future<User> currentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return _userFromFirebase(user);
  }

  //This function allows guest user access
  Future<User> signInAnonymously() async {
    final authResult = await _firebaseAuth.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final authResult = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);

    return _userFromFirebase(authResult.user);
  }


  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);

  }

  Future<void> signUp(String name,String email, String password) async {
    final authResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    //After the user is register successfully
    //Try to create a new record on FireStore
    //Send and email verification right after the user signin

    try {
      //Send an email verification
      await authResult.user.sendEmailVerification();
    } catch (e) {
      print("An error occured while trying to send email verification");
      print(e.message);
    }
    //Force the app not to redirect user to the dashboard they have to verify email
    //Bypass stream builder in actmain.dart
    return _userFromFirebase(null);
  }

  //Sign in with Google
  //Create a new user record process handled in Dashboard
  Future<User> signInWithGoogle(BuildContext context) async {

    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken != null && googleAuth.accessToken != null) {
        final authResult = await _firebaseAuth.signInWithCredential(
          GoogleAuthProvider.getCredential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          ),
        );

        return _userFromFirebase(authResult.user);
      } else {
        throw StateError('ERROR_MISSING_GOOGLE_AUTH_TOKEN');
      }
    } else {
      throw StateError('ERROR_ABORTED_BY_USER');
    }
  }

  //Sign in with facebook
  //Create a new user record process handled in Dashboard
  Future<User> signInWithFacebook() async {
    final facebookLogin = FacebookLogin();
    FacebookLoginResult result = await facebookLogin.logIn(
      ['public_profile'],
    );
    if (result.accessToken != null) {
      final authResult = await _firebaseAuth.signInWithCredential(
        FacebookAuthProvider.getCredential(
          accessToken: result.accessToken.token,
        ),
      );

      return _userFromFirebase(authResult.user);
    } else {
      throw StateError(
        'ERROR_ABORTED_BY_USER',

      );
    }
  }


  //Sign out function
  //End all session
  Future<void> SignOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    final facebookLogin = FacebookLogin();
    await facebookLogin.logOut();

    return await _firebaseAuth.signOut();
  }


}
