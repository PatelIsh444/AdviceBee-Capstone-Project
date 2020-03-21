import 'Dashboard.dart';
import './utils/commonFunctions.dart';
import 'package:flutter/material.dart';
import 'MoreMenu.dart';
import 'QuestionPage.dart';

class AboutUsPage extends StatefulWidget {
  @override
  AboutUsPageState createState() => AboutUsPageState();
}

class AboutUsPageState extends State<AboutUsPage> {
  GlobalKey key = GlobalKey();
  int currentTab=3;
  Widget buildText(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w400,//try changing weight to w500 if not thin

      color: Colors.black,
      fontSize: 18.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Text(
        "AdviceBee is a place where people are encouraged to ask questions and "
            "share advice with others.",
        style: bioTextStyle,
      ),

    );
  }

  Widget buildHeader(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w700,//try changing weight to w500 if not thin
      color: Colors.black,
      fontSize: 22.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
          minWidth: MediaQuery.of(context).size.width,
      ),
      child: Text(
        "Terms of Service",
        style: bioTextStyle,
        textAlign: TextAlign.left,

      ),
    );
  }

  Widget buildText2(BuildContext context) {
    TextStyle bioTextStyle = TextStyle(
      fontFamily: 'Spectral',
      fontWeight: FontWeight.w400,//try changing weight to w500 if not thin
      color: Colors.black,
      fontSize: 18.0,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: Text(
        "AdviceBee and its creators are not responsible for any advice given to "
            "users of the application.\n"

        "\nAdvice is given by the community and can't be monitored by the "
            "AdviceBee team to ensure accuracy. Some advice may be inaccurate or"
            " not applicable to the users intentions. It is suggested that users "
            "take advice as suggestions only.\n"

        "\nAdviceBee does not have filters to remove or block age restricted "
            "content. However, a user can report any content that they believe "
            "is inapproprate, and a moderator will take corrective action.\n"

        "\nAdviceBee is not responsible for any financial transactions between "
            "multiple parties. Any transaction of currency is "
            "to be handled off of the application and at the risk of the user.\n"

        "\nPosts on AdviceBee aren't intended to be a substitute for professional medical advice,"
            " diagnosis, or treatment. Always seek the advice of your physician or other qualified"
            " health provider with any questions you may have regarding a medical condition. "
            "Never disregard professional medical advice or delay in seeking it because of something "
            "you have read on AdviceBee.\n"

            "\nWhile, AdviceBee is a advice sharing platform, it is strongly "
            "advised not to share personal information (ie. phone numbers, "
            "addresses, debit/credit card info, banking info, etc.) through the "
            "application.\n",
        style: bioTextStyle,
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        centerTitle: true,
        automaticallyImplyLeading: true,
        title: Text("About Us"),
      ),
      body: Stack(
        children:<Widget>[
          SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                buildText(context),
                buildHeader(context),
                buildText2(context),
              ],
            ),
          ),
          ),

        ],
      ),
      floatingActionButton:
      FloatingActionButton(
        onPressed: () {
          if (CurrentUser.isNotGuest) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => postQuestion(null, null) //AddPost(),
                ));
          } else{
            guestUserSignInMessage(context);
          }
        },
        heroTag: "aboutUsfeHero",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 12,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
    );
  }
}