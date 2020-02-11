import 'MoreMenu.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cloud_firestore/cloud_firestore.dart';

Widget postChartButton(String groupId, String postId, String pieOrNumber,
    BuildContext context, String groups_or_topics, int numberOfResponses) {
  Size screenSize = MediaQuery.of(context).size;
  return GestureDetector(
    onTap: () {
      print(numberOfResponses);
      pieOrNumber.toLowerCase();
      if (pieOrNumber == "pie") {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) =>
                PieChartTest(groupId, postId, groups_or_topics)));
      } else if (pieOrNumber == "number") {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) =>
                NumberChartTest(groupId, postId, groups_or_topics)));
      }
    },
    child: Container(
      height: 40.0,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
        color: Color(0xFF009688),
      ),
      child: Center(
        child: Text(
          pieOrNumber == "pie" ? "View Pie Chart" : "View Line Chart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class PieChartTest extends StatefulWidget {
  final String groupID;
  final String postID;
  final String groups_or_topics;
  PieChartTest(this.groupID, this.postID, this.groups_or_topics);

  @override
  PieChartTestState createState() => PieChartTestState();
}

class PieChartTestState extends State<PieChartTest> {
  int currentTab = 3;
  GlobalKey key = GlobalKey();
  List<QuestionStats> answerList = new List();

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    List<QuestionStats> tempList = new List();
    var tempStrings = new List();
    String declaredGroupOrTopicID = widget.groupID;
    String declaredPostId = widget.postID;
    String questionCollection;

    if (widget.groups_or_topics == "topics") {
      questionCollection = "topicQuestions";
    } else {
      questionCollection = "groupQuestions";
    }

    await Firestore.instance
        .collection(widget.groups_or_topics)
        .document(declaredGroupOrTopicID) //Group ID
        .collection(questionCollection)
        .document(declaredPostId) //Post ID within group
        .collection('responses')
        .getDocuments()
        .then((QuerySnapshot data) => data.documents.forEach((doc) {
              tempStrings.add(doc["answer"]);
            }));

    if (tempStrings.isNotEmpty) {
      tempList = calculateValues(tempStrings);
      printValues(tempList);

      setState(() {
        print(tempList);
        answerList = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Chart"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(5, 0, 5, 100),
        child: Center(
          child: Container(
            child: Column(
              //child: PieOutsideLabelChart(PieOutsideLabelChart._createSampleData()),
              children: <Widget>[
                Text(
                  'Question Statistics',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Container(
                  width: screenSize.width - 50,
                  height: screenSize.width - 50,
                  child:
                      //PointsLineChart(PointsLineChart._createSampleData()),
                      answerList != null && answerList.length > 0
                          ? PieOutsideLabelChart(
                              PieOutsideLabelChart._createSampleData(
                                  answerList))
                          : Text(
                              "There are no responses yet, answer the question and try again!",
                              style: TextStyle(
                                fontSize: 25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
    );
  }
}

class PieOutsideLabelChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  //final bool animate;

  PieOutsideLabelChart(this.seriesList);

  @override
  Widget build(BuildContext context) {
    // Add an [ArcLabelDecorator] configured to render labels outside of the
    // arc with a leader line.
    //
    // Text style for inside / outside can be controlled independently by
    // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
    //
    // Example configuring different styles for inside/outside:
    //       new charts.ArcLabelDecorator(
    //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
    //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
    return new charts.PieChart(
      seriesList,
      animate: true,
      animationDuration: Duration(seconds: 1),
      behaviors: [
        new charts.DatumLegend(
          outsideJustification: charts.OutsideJustification.middle,
          horizontalFirst: false,
          desiredMaxRows: 5,
          cellPadding: new EdgeInsets.only(right: 4.0, bottom: 4.0, top: 4.0),
          entryTextStyle: charts.TextStyleSpec(
              color: charts.MaterialPalette.black,
              fontFamily: 'Georgia',
              fontSize: 18),
        )
      ],
      defaultRenderer:
          new charts.ArcRendererConfig(arcWidth: 80, arcRendererDecorators: [
        new charts.ArcLabelDecorator(
            labelPosition: charts.ArcLabelPosition.auto,
            outsideLabelStyleSpec: charts.TextStyleSpec(
              color: charts.Color.black,
              fontSize: 15,
            ),
            insideLabelStyleSpec: charts.TextStyleSpec(
              color: charts.Color.black,
              fontSize: 15,
            ))
      ]),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<QuestionStats, dynamic>> _createSampleData(
      List<QuestionStats> data) {
    if (data != null) {
      for (int i = 0; i < data.length; i++) {
        data[i].assignedLetter = String.fromCharCode(i + 65);
      }
    }

    return [
      new charts.Series<QuestionStats, dynamic>(
        id: 'Statistics',
        domainFn: (QuestionStats question, _) =>
            question.assignedLetter +
            ": " + //Shortens string that is greater than 24 characters
            (question.answerLabel.length > 27
                ? (question.answerLabel.substring(0, 25) + "..")
                : question.answerLabel),
        measureFn: (QuestionStats question, _) => question.amountOfAnswers,
        data: data,
        // Set a label accessor to control the text of the arc label.
        labelAccessorFn: (QuestionStats row, _) =>
            '${row.assignedLetter}: ${row.amountOfAnswers}',
      )
    ];
  }
}

/// Sample linear data type.
class QuestionStats {
  String answerLabel;
  int amountOfAnswers;
  String assignedLetter;

  QuestionStats(this.answerLabel, this.amountOfAnswers);
}

void printValues(List<QuestionStats> tempList) {
  for (int i = 0; i < tempList.length; i++) {
    print("Object loop ${tempList.elementAt(i).answerLabel}"
        " = ${tempList.elementAt(i).amountOfAnswers}");
  }
}

List<QuestionStats> calculateValues(var tempStrings) {
  List<QuestionStats> tempList = new List();
  int counter = 0;
  tempStrings.sort();
  String temp = tempStrings[0].toString();

  for (int i = 0; i < tempStrings.length; i++) {
    if (temp == tempStrings[i].toString()) {
      counter++;
    } else {
      //print("Future Loop ${tempStrings[i-1]} = $counter");
      tempList.add(new QuestionStats(temp, counter));
      counter = 1;
      temp = tempStrings[i];
    }
  }
  tempList.add(new QuestionStats(tempStrings[tempStrings.length - 1], counter));
  return tempList;
}

class PointsLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  PointsLineChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList,
        animate: true,
        animationDuration: Duration(seconds: 1),
        behaviors: [
          new charts.ChartTitle('Values',
              behaviorPosition: charts.BehaviorPosition.bottom,
              titleStyleSpec: charts.TextStyleSpec(fontSize: 11),
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea),
          new charts.ChartTitle('Frequency',
              behaviorPosition: charts.BehaviorPosition.start,
              titleStyleSpec: charts.TextStyleSpec(fontSize: 11),
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea)
        ],
        defaultRenderer: new charts.LineRendererConfig(includePoints: true));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<NumberStats, int>> _createSampleData(
      List<NumberStats> data) {
    return [
      new charts.Series<NumberStats, int>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (NumberStats sales, _) => sales.year.round(),
        measureFn: (NumberStats sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
class NumberStats {
  final double year;
  final int sales;

  NumberStats(this.year, this.sales);
}

List<NumberStats> calculateNumberValues(var tempNumbers) {
  List<NumberStats> tempList = new List();
  int counter = 0;
  tempNumbers.sort();
  double temp = tempNumbers[0];

  for (int i = 0; i < tempNumbers.length; i++) {
    if (temp == tempNumbers[i]) {
      counter++;
    } else {
      //print("Future Loop ${tempNumbers[i-1]} = $counter");
      tempList.add(new NumberStats(temp, counter));
      counter = 1;
      temp = tempNumbers[i];
    }
  }
  tempList.add(new NumberStats(tempNumbers[tempNumbers.length - 1], counter));
  return tempList;
}

class NumberChartTest extends StatefulWidget {
  final String groupID;
  final String postID;
  final String groups_or_topics;
  NumberChartTest(this.groupID, this.postID, this.groups_or_topics);

  @override
  NumberChartTestState createState() => NumberChartTestState();
}

class NumberChartTestState extends State<NumberChartTest> {
  int currentTab = 3;
  GlobalKey key = GlobalKey();
  List<NumberStats> answerList = new List();

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    List<NumberStats> tempList = new List();
    var tempNumbers = new List();
    String declaredGroupOrTopicID = widget.groupID;
    String declaredPostId = widget.postID;
    String questionCollection;
    if (widget.groups_or_topics == "topics") {
      questionCollection = "topicQuestions";
    } else {
      questionCollection = "groupQuestions";
    }

    await Firestore.instance
        .collection(widget.groups_or_topics)
        .document(declaredGroupOrTopicID) //Group ID
        .collection(questionCollection)
        .document(declaredPostId) //Post ID within group
        .collection('responses')
        .getDocuments()
        .then((QuerySnapshot data) => data.documents.forEach((doc) {
              tempNumbers.add(doc["answer"]);
            }));

    if (tempNumbers.isNotEmpty) {
      tempList = calculateNumberValues(tempNumbers);

      setState(() {
        answerList = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Size screenSize=MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Chart"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(5, 0, 5, 100),
        child: Center(
          child: Container(
            child: Column(
              //child: PieOutsideLabelChart(PieOutsideLabelChart._createSampleData()),
              children: <Widget>[
                Text(
                  'Question Statistics',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Expanded(
                  child: answerList != null && answerList.length > 0
                      ? PointsLineChart(
                          PointsLineChart._createSampleData(answerList))
                      : Text(
                          "There are no responses yet, answer the question and try again!",
                          style: TextStyle(
                            fontSize: 25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: globalNavigationBar(currentTab, context, key, false),
    );
  }
}
