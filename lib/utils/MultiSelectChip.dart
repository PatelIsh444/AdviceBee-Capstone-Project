/*
Choice Chips Class, Present all item within reportList
And output to selectedChoices list
 */

import '../User.dart';
import 'package:flutter/material.dart';

class MultiSelectChip extends StatefulWidget {
  final List<String> reportList;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.reportList, {this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedChoices = List();

  _buildChoiceList() {
    List<Widget> choices = List();

    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedChoices.contains(item),
          onSelected: (selected) {
            setState(() {
              selectedChoices.contains(item)
                  ? selectedChoices.remove(item)
                  : selectedChoices.add(item);
              widget.onSelectionChanged(selectedChoices);
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

//MultiSelectChip class specifically for a User. Used for advisor system.
class MultiSelectChipUser extends StatefulWidget{
  final List<User> userList;
  final Function(List<String>) onSelectionChanged;
  List<String> alreadySelected;

  MultiSelectChipUser(this.userList, this.alreadySelected ,{this.onSelectionChanged});

  @override
  _MultiSelectChipUserState createState() => _MultiSelectChipUserState();
}

class _MultiSelectChipUserState extends State<MultiSelectChipUser> {
  List<String> selectedChoices = List();

  @override
  initState(){
    super.initState();
    selectedChoices = widget.alreadySelected;
  }

  _buildChoiceList() {
    List<Widget> choices = List();

    widget.userList.forEach((user) {
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
          label: Text(user.displayName),
          selected: selectedChoices.contains(user.userID),
          onSelected: (selected) {
            setState(() {
              selectedChoices.contains(user.userID)
                  ? selectedChoices.remove(user.userID)
                  : selectedChoices.add(user.userID);
              widget.onSelectionChanged(selectedChoices);
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