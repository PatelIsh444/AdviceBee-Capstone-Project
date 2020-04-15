# AdviceBee


AdviceBee, is a Flutter Mobile application. In this app, a user will be able to log into the site and view & control various aspects of the application. These include adding questions, responding, messaging, creating groups, reporting, and blocking and acting on other user generated content/messages, growing their rank or losing their rank based on activity, and view the front facing application built from the AdviceBee application database (Firebase).

## Installation

This application uses Flutter, in order to install and run this program you must do the following:

0. Pull down the repo to your local machine.
1. Go to Flutter.dev and click on Get Started (https://flutter.dev/docs/get-started/install).
2. Select the corresponding operating system and follow the install instructions.

#### Windows Installation (You will not be able to emulate iOS Flutter app without XCode or MacOS)
1. Go to Flutter Dev Windows installation instruction page (https://flutter.dev/docs/get-started/install/windows)
2. Scroll down and click the "Get the Flutter SDK" download button to start the Flutter download
3. Install [Android Studio](https://developer.android.com/studio).
4. Install [Visual Studio Code](https://code.visualstudio.com/download).
5. Install the [Flutter Plugin](https://flutter.dev/docs/development/tools/vs-code) on Visual Studio Code.
6. Install [Firebase CLI](https://firebase.google.com/docs/cli#install-cli-windows)
7. User Terminal to `cd` into the `AdviceBee`  directory of the local cloned repo.
8. Run `flutter pub get`
9. Run `flutter run` to test the application in Debug mode
10.1 Run `flutter build apk --debug` to build the Android application in Debug mode
10.2 Run `flutter build apk --release` to build the Android application in Release mode

#### MacOS Installation
1. Go to Flutter Dev MacOS installation instruction page (https://flutter.dev/docs/get-started/install/macos)
2. Scroll down and click the "Get the Flutter SDK" download button to start the Flutter download
3. Install [Android Studio](https://developer.android.com/studio).
4. Install [XCode] (https://apps.apple.com/us/app/xcode/id497799835)
5. Install [Visual Studio Code](https://code.visualstudio.com/download).
6. Install the [Flutter Plugin](https://flutter.dev/docs/development/tools/vs-code) on Visual Studio Code.
7. Install [Firebase CLI](https://firebase.google.com/docs/cli#install-cli-mac-linux)
8. User Terminal to `cd` into the `AdviceBee`  directory of the local cloned repo.
9. Run `flutter pub get`
10. Run `flutter run` to test the application in Debug mode

## Running
Once all the steps in the Installation section have been completed, its time to run the app.

### Using Terminal
1. User Terminal to `cd` into the `AdviceBee`  directory of the local cloned repo.
2. Run `flutter run` to test the application in Debug mode

### Using Visual Studio Code (Preferred)
1. Open the project using Visual Studio Code.
2. Open a `.dart` file in the `AdviceBee/lib` directory.
3. Visual Studio Code should auto-detect Flutter and allow you to change the device to run the code on in the bottom toolbar on the bottom right.
4. Choose the device you have plugged in as your device.
5. Hit F5 on your keyboard to run the application.

## Building
Once you've made the changes, tested the changes, and are ready to build the application for Android or iOS here are the instructions.

### Using Terminal
#### Building an Android apk from Flutter code
##### Building a Debug app
1. Run `flutter build apk --debug` to build the Android application in Debug mode
##### Building a Release app
1. Run `flutter build apk --release` to build the Android application in Release mode

#### Building an iOS app from Flutter code
##### Building a Debug app
1. Run `flutter build ios --debug` to build the iOS application in Debug mode
##### Building a Release app
1. Run `flutter build ios --release` to build the iOS application in Release mode

## Firebase Functions
Firebase CLI functions control some aspects of the application like daily updates and the notification service and the communication from the Firestore to the Firebase Cloud Messaging

### Using Terminal
#### Modifications
1. Open the project using Visual Studio Code.
2. Use Terminal to `cd` into the `AdviceBee/Firebase Functions/functions`  directory of the local cloned repo.
3. Modify the `index.js` file and include any new Firebase Functions.
#### Login to Firebase Server
1. Open the project using Visual Studio Code.
2. Use Terminal to `cd` into the `AdviceBee/Firebase Functions/functions`  directory of the local cloned repo.
3. Run `firebase login` to login to the AdviceBee Firebase
#### Deploy Firebase Functions
1. Open the project using Visual Studio Code.
2. Use Terminal to `cd` into the `AdviceBee/Firebase Functions/functions`  directory of the local cloned repo.
3. Login to firebase using the above section
4. Run `firebase deploy` to deploy the updated functions file to Firebase

## Using
Upon successful installation and running of the application on Chome, the first screen you will see is a Login Page.
1.1 Use the email and password credentials of a registered user to fill out the form. 
1.2 Use the Gmail or Facebook sign in of a registered user to login
1.3 Register a new user using Gmail or Facebook or Email and Password
2. Once successfully logged in, you will land on the main page, the Dashboard page.
3. You can Use the navigation bar to navigate the other pages, and also sign out once you are complete.
