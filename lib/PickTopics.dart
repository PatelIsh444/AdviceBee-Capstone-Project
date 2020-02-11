import 'Dashboard.dart';
import 'package:flutter/material.dart';

class PickTopic extends StatefulWidget {
  static String id = 'picktopic';

  @override
  _PickTopicState createState() => _PickTopicState();
}

class _PickTopicState extends State<PickTopic> {


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(

        title: Text("What are your interests?", style: TextStyle(color: Colors.white,),),

      ),
      body: Column(
        children: <Widget>[

          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left:8.0),
            child: Align
              (
              alignment: Alignment.centerLeft,
              child: Container(
                child: Wrap(
                  spacing: 5.0,
                  runSpacing: 5.0,
                  children: <Widget>[
                    filterChipWidget(chipName: 'Technology'),
                    filterChipWidget(chipName: 'Movies'),
                    filterChipWidget(chipName: 'Health'),
                    filterChipWidget(chipName: 'Books'),
                    filterChipWidget(chipName: 'Photography'),
                    filterChipWidget(chipName: 'Design'),
                    filterChipWidget(chipName: 'Psychology'),
                    filterChipWidget(chipName: 'Business'),
                    filterChipWidget(chipName: 'Jobs'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
          ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          onPressed: () {
            Navigator.pushNamed(context, Dashboard.id);
          },
          padding: EdgeInsets.all(20),
          color: Theme.of(context).primaryColor,
          child: Text('CONTINUE', style: TextStyle(color: Colors.white)),
        ),
      ),
        ],
      ),
    );
  }

}

Widget _titleContainer(String myTitle) {
  return Text(
    myTitle,
    style: TextStyle(
        color: Colors.teal, fontSize: 24.0, fontWeight: FontWeight.bold),
  );
}

class filterChipWidget extends StatefulWidget {
  final String chipName;

  filterChipWidget({Key key, this.chipName}) : super(key: key);

  @override
  _filterChipWidgetState createState() => _filterChipWidgetState();
}

class _filterChipWidgetState extends State<filterChipWidget> {
  var _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.chipName),
      labelStyle: TextStyle(color: Colors.white,fontSize: 16.0,fontWeight: FontWeight.bold),
      selected: _isSelected,
      shape:RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            30.0),),
      backgroundColor: Colors.teal[200],
      onSelected: (isSelected) {
        setState(() {
          _isSelected = isSelected;
        });
      },
      selectedColor: Colors.teal,);
  }
}