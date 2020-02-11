/*
Choice Chips Class, Present all item within reportList
And output to selectedChoices list
 */

import '../Dashboard.dart';
import 'package:flutter/material.dart';

class MultiSelectChip extends StatefulWidget {
  final String type;
  final List<String> reportList;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.type, this.reportList, {this.onSelectionChanged});


  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}


class _MultiSelectChipState extends State<MultiSelectChip> {
  //initialized two lists
  //one designated for holding reports
  List<String> selectedReportChoices = List();
  //Added to fix null iterator bug
  List<String> selectedChoices = CurrentUser != null ? new List<String>.from(CurrentUser?.myTopics): List();


  _buildChoiceList() {

    List<Widget> choices = List();
    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          selectedShadowColor: Colors.blue,
          backgroundColor: Colors.teal[50],
          selectedColor: Colors.amber,
          padding: EdgeInsets.all(5.0),
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
          ),
          label: Text(item),
          selected: widget.type == "topic" && selectedChoices != null ? selectedChoices.contains(item): selectedReportChoices.contains(item) ,
          onSelected: (selected) {
            setState(() {
              if(widget.type == "topic") {
                selectedChoices.contains(item)
                    ? selectedChoices.remove(item)
                    : selectedChoices.add(item);
                widget.onSelectionChanged(selectedChoices);
              }
              else {
                selectedReportChoices.contains(item)
                    ? selectedReportChoices.remove(item)
                    : selectedReportChoices.add(item);
                widget.onSelectionChanged(selectedReportChoices);
              }

            });
          },
        ),
      ));
    });

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildChoiceList(),
    );
  }
}
