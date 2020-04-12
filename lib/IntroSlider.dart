import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:v0/utils/commonFunctions.dart';
import 'Dashboard.dart';

class IntroSlider extends StatefulWidget {
  @override
  IntroSliderState createState() => IntroSliderState();
}

class IntroSliderState extends State<IntroSlider> with WidgetsBindingObserver {
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
      body: 'Welcome to AdviceBee,\n'
          ' A leading Advice getting Softwere.'
          'AdviceBee is designed for the students of Wayne State University'
          'This Software will help students to solve their difficulties in any subject'
          'by connecting best experts to the students.',
      title: 'Advice Bee',
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 50.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 20.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        pageColor: const Color(0xff9fa8da),
      ),
      image: Center(child: Image.asset("images/logoTeal.png", height: 270.0)),
    ),
    PageViewModel(
      title: "Rank System",
      body: "Larvae: 0-499 Points\n"
          "Worker Bee: 500-999 Points\n"
          "Queen Bee: 1000+ Points\n"
          "You can earn 10 points responsing to a qestion. ",
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 50.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 20.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        pageColor: const Color(0xff80cbc4),
      ),
      image: Center(child: Image.asset("images/logoTeal.png", height: 270.0)),
    ),
    PageViewModel(
      title: "Posting Questions",
      body: "Based on your status you will be given a certaing amount of questions daily."
          " If you run out, you can either wait for the next day or buy more!!",
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 50.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 20.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        pageColor: const Color(0xff80cbc4),
      ),
      image: Center(child: Image.asset("images/logoTeal.png", height: 270.0)),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AdviceBee',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: IntroductionScreen(
        pages: pages,
        onDone: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(),
              ));
        },
        onSkip: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(),
              ));
        },
        showSkipButton: true,
        skip: const Text("Skip", style: TextStyle(fontWeight: FontWeight.w600)),
        next: const Icon(Icons.navigate_next),
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
        dotsDecorator: DotsDecorator(
            size: const Size.square(12.0),
            activeSize: const Size(20.0, 10.0),
            color: Colors.black,
            spacing: const EdgeInsets.symmetric(horizontal: 3.0),
            activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0))),
      ),
    );
  }
}
