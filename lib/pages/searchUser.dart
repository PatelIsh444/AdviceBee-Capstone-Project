import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../newProfile.dart';

class searchUser extends SearchDelegate<String> {
  List<DocumentSnapshot> suggestions = [];

  getUserData(s) async {
    await Firestore.instance
        .collection("users")
        .where("displayId", whereIn: s)
        .getDocuments()
        .then((docs) {
      print(docs);
    });
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = "";
          })
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    Stream<QuerySnapshot> stream =
        Firestore.instance.collection('users').snapshots();
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        } else {
          suggestions = snapshot.data.documents
              .where((d) =>
                  d["displayName"].toString().toLowerCase().contains(query))
              .toList();

          return SuggestionList(
            query: query,
            suggestions: suggestions,
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Stream<QuerySnapshot> stream =
        Firestore.instance.collection('users').snapshots();
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        } else {
          suggestions = snapshot.data.documents
              .where((d) =>
                  d["displayName"].toString().toLowerCase().contains(query))
              .toList();

          return SuggestionList(
            query: query,
            suggestions: suggestions,
          );
        }
      },
    );
  }
}

class SuggestionList extends StatelessWidget {
  const SuggestionList({this.suggestions, this.query});

  final List<DocumentSnapshot> suggestions;
  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        if (query == null) {
          return Container();
        }
        String avatar = suggestions.elementAt(index)["profilePicURL"];
        return ListTile(
          leading: Material(
            child: avatar != null
                ? CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                      width: 50.0,
                      height: 50.0,
                      padding: EdgeInsets.all(15.0),
                    ),
                    imageUrl: avatar,
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.account_circle,
                    size: 50.0,
                    color: Colors.grey,
                  ),
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
            clipBehavior: Clip.hardEdge,
          ),
          title: RichText(
            text: TextSpan(
              text: suggestions.elementAt(index)["displayName"],
              //style: theme.textTheme.subtitle1.copyWith(fontWeight: FontWeight.bold),
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserDetailsPage(suggestions.elementAt(index).documentID),
                ));
          },
        );
      },
    );
  }
}
