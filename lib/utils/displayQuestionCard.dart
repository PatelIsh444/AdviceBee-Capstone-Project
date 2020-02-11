import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
//This class is user for Favorite Post and My Post
//Display post title and Description along with
//image based on question type

class displayQuestionCard extends StatefulWidget {
  String title;
  String description;
  String type;

  displayQuestionCard(this.title, this.description,this.type);


  @override
  _displayQuestionCardState createState() => _displayQuestionCardState();
}

class _displayQuestionCardState extends State<displayQuestionCard> {
  @override

  Widget _getImageByType(String type){
    switch(type) {
      case "general":
        {
          return new Image(image: AssetImage('images/basic.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);
        }
      case "mchoice":
        {
          return new Image(image: AssetImage('images/choice.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);
        }
      case "number":
        {

          return new Image(image: AssetImage('images/statistic.png') , fit: BoxFit.cover,width: 65.0,height: 65.0,);
        }
      case "profile":
        {
          return Container();
        }
    }
  }

  Widget _getColumText(String title,String description){

    return new Expanded(
        child: new Container(
          margin: new EdgeInsets.all(10.0),
          child: new Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: <Widget>[
              _getTitleWidget(title),
              _getDescriptionWidget(description)],
          ),
        )
    );
  }

  Widget _getTitleWidget(String curencyName){
    return new Text(
      curencyName,
      maxLines: 1,
      style: new TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _getDescriptionWidget(String description){
    return new Container(
      margin: new EdgeInsets.only(top: 5.0),
      child: new AutoSizeText(description,maxLines: 1,),
    );
  }


  Widget build(BuildContext context) {
    return new Container(
      height: 65.0,
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _getImageByType(widget.type),
          _getColumText(widget.title,widget.description),
        ],

      ),
    );
  }


}
