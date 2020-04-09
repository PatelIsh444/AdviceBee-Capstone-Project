import 'GroupProfile.dart';
import 'newProfile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './utils/GroupInformation.dart';
import 'QuestionPage.dart';

class SearchList {
  String name; //This can be either group name, post name, or display name
  String type; //This can be "group", "user", or "post"
  String firstDocumentID; //This can be a groupID, topic name, or userID
  String secondDocumentID; //This can be a postID
  GroupInformation groupInfo;

  /*Clarification for first and second document IDs
  * Firebase Structure
  * Collection->firstDocumentID->Collection->secondDocumentID*/

  SearchList(this.name, this.type, this.firstDocumentID, this.secondDocumentID,
      this.groupInfo);
}

class TestSearch extends SearchDelegate<String> {
  List<SearchList> databaseSearchQuery = new List();

  TestSearch(this.databaseSearchQuery);

  final recentSearches = [];

/* Function to bold users query in search results */
  TextSpan boldSearchText(String suggestionList, String query) {
    //If nothing is typed return the empty list or recently typed list
    if (query.length < 1) {
      return TextSpan(
        text: suggestionList.substring(query.length),
        style: TextStyle(color: Colors.grey),
      );
    }

    int boldIndex = 0;
    int querySize = query.length;
    int stringSize = suggestionList.length;

    /* String matching algorithm
    https://www.geeksforgeeks.org/naive-algorithm-for-pattern-searching/ */
    for (int i = 0; i <= stringSize - querySize; i++) {
      int j;

      for (j = 0; j < querySize; j++) {
        if (suggestionList[i + j] != query[j]) break;
      }

      if (j == querySize) boldIndex = i;
    }

    /* Return 3 different sets of text. The first set of text is grey, the
    * second set of text is bold, the third set of text is grey. The users
    * query is in bold text */
    return TextSpan(
        text: suggestionList.substring(0, boldIndex),
        style: TextStyle(
          color: Colors.grey,
        ),
        children: [
          TextSpan(
            text: suggestionList.substring(boldIndex, query.length + boldIndex),
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: suggestionList.substring(query.length + boldIndex),
            style: TextStyle(color: Colors.grey),
          ),
        ]);
  }

  Icon returnIcon(String searchObjectType) {
    if (searchObjectType == "group") {
      return Icon(Icons.people);
    } else if (searchObjectType == "user") {
      return Icon(Icons.person);
    } else if (searchObjectType == "dashboard") {
      return Icon(Icons.question_answer);
    } else
      return Icon(Icons.error);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    //Actions for the search bar
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    //Leading icon on the left of search bar
    return IconButton(
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
    /*Results from clicking search after typing in your search parameters*/
    return resultList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    //List of items that is shown before user clicks the search button
    return resultList();
  }

  Widget resultList() {
    final suggestionList = databaseSearchQuery
        .where(
            (object) => object.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final suggUsers = searchResults("user");
    final suggDash = searchResults("dashboard");
    final suggGroup = searchResults("group");
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Container(
            constraints: BoxConstraints.expand(height: 50),
            child: TabBar(tabs: [
              Tab(child: Text("Users", style: TextStyle(color: Colors.teal),),),
              Tab(child: Text("Posts", style: TextStyle(color: Colors.teal),),),
              Tab(child: Text("Groups", style: TextStyle(color: Colors.teal),),),
            ]),
          ),
          Expanded(
            child: Container(
              child: TabBarView(children: [
                Container(
                  child: ListView.builder(
                    itemBuilder: (context, index) => ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserDetailsPage(
                                    suggUsers[index].firstDocumentID)));
                      },
                      leading: returnIcon(suggUsers[index].type),
                      title: RichText(
                        text: boldSearchText(suggUsers[index].name, query),
                      ),
                    ),
                    itemCount: suggUsers.length,
                  ),
                ),
                Container(
                  child: ListView.builder(
                    itemBuilder: (context, index) => ListTile(
                      onTap: () {
                        questions selectedPost = getQuestion(
                            suggDash[index].firstDocumentID,
                            suggDash[index].secondDocumentID);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostPage(
                                  selectedPost,
                                  suggDash[index].firstDocumentID,
                                  suggDash[index].secondDocumentID,
                                  "topics"),
                            ));
                      },
                      leading: returnIcon(suggDash[index].type),
                      title: RichText(
                        text: boldSearchText(suggDash[index].name, query),
                      ),
                    ),
                    itemCount: suggDash.length,
                  ),
                ),
                Container(
                  child: ListView.builder(
                    itemBuilder: (context, index) => ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupProfile(suggGroup[index].groupInfo),
                            ));
                      },
                      leading: returnIcon(suggGroup[index].type),
                      title: RichText(
                        text: boldSearchText(suggGroup[index].name, query),
                      ),
                    ),
                    itemCount: suggGroup.length,
                  ),
                ),
              ]),
            ),
          )
        ],
      ),
    );
//          ListView.builder(
//            itemBuilder: (context, index) => ListTile(
//              onTap: () {
//                //Calls the "buildResults" Function
//                //showResults(context);
//                if (suggestionList[index].type == "group") {
//                  Navigator.push(
//                      context,
//                      MaterialPageRoute(
//                        builder: (context) =>
//                            GroupProfile(suggestionList[index].groupInfo),
//                      ));
//                } else if (suggestionList[index].type == "user") {
//                  Navigator.push(
//                      context,
//                      MaterialPageRoute(
//                        builder: (context) => UserDetailsPage(
//                            suggestionList[index].firstDocumentID),
//                      ));
//                } else if (suggestionList[index].type == "dashboard") {
//                  questions selectedPost = getQuestion(
//                      suggestionList[index].firstDocumentID,
//                      suggestionList[index].secondDocumentID);
//                  Navigator.push(
//                      context,
//                      MaterialPageRoute(
//                        builder: (context) => PostPage(
//                            selectedPost,
//                            suggestionList[index].firstDocumentID,
//                            suggestionList[index].secondDocumentID,
//                            "topics"),
//                      ));
//                }
//              },
//              leading: returnIcon(suggestionList[index].type),
//              title: RichText(
//                text: boldSearchText(suggestionList[index].name, query),
//              ),
//            ),
//            itemCount: suggestionList.length,
//          ),
  }

  searchResults(String type) {
    final suggestionList = databaseSearchQuery
        .where((object) =>
            object.name.toLowerCase().contains(query.toLowerCase()) &&
            object.type.toLowerCase() == type.toLowerCase())
        .toList();
    return suggestionList;
  }

  questions getQuestion(String firstId, String secondId) {
    questions getPost;

    Firestore.instance
        .collection('topics')
        .document(firstId)
        .collection('topicQuestions')
        .document(secondId)
        .get()
        .then((DocumentSnapshot doc) {
      switch (doc["questionType"]) {
        case 0:
          {
            getPost = new basicQuestionInfo(
              doc.documentID,
              doc["question"],
              doc["description"],
              doc["createdBy"],
              doc["userDisplayName"],
              doc["dateCreated"],
              doc["numOfResponses"],
              doc["questionType"],
              doc["topicName"],
              doc["likes"],
              doc["views"],
              doc["reports"],
              doc["anonymous"] == null ? false : doc["anonymous"],
              doc["multipleResponses"] == null
                  ? false
                  : doc["multipleResponses"],
              doc["imageURL"] == null ? null : doc["imageURL"],
            );
            break;
          }
        case 1:
          {
            getPost = new MultiChoiceQuestion(
              doc.documentID,
              doc["question"],
              doc["description"],
              doc["createdBy"],
              doc["userDisplayName"],
              doc["dateCreated"],
              doc["numOfResponses"],
              doc["questionType"],
              doc["choices"],
              doc["topicName"],
              doc["likes"],
              doc["views"],
              doc["reports"],
              doc["anonymous"] == null ? false : doc["anonymous"],
              doc["multipleResponses"] == null
                  ? false
                  : doc["multipleResponses"],
              doc["imageURL"] == null ? null : doc["imageURL"],
            );
            break;
          }
        case 2:
          {
            getPost = new NumberValueQuestion(
              doc.documentID,
              doc["question"],
              doc["description"],
              doc["createdBy"],
              doc["userDisplayName"],
              doc["dateCreated"],
              doc["numOfResponses"],
              doc["questionType"],
              doc["topicName"],
              doc["likes"],
              doc["views"],
              doc["reports"],
              doc["anonymous"] == null ? false : doc["anonymous"],
              doc["multipleResponses"] == null
                  ? false
                  : doc["multipleResponses"],
              doc["imageURL"] == null ? null : doc["imageURL"],
            );
            break;
          }
      }
    });
    return getPost;
  }
}
