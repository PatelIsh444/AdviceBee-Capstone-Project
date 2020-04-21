
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:credit_card/credit_card_form.dart';
import 'package:credit_card/credit_card_model.dart';
import 'package:credit_card/credit_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';

import 'package:v0/services/PaymentService.dart';
import 'package:v0/utils/commonFunctions.dart';

import '../Dashboard.dart';
import '../Profile.dart';

class PaymentHistory extends StatefulWidget {
  @override
  _PaymentHistoryState createState() => new _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  String _error = 'Pending.';

  var paymentService = new PaymentService();

  ScrollController _controller = ScrollController();

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  int cardMonth = 12;
  int cardYear = 21;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  get currentTab => null;

  @override
  initState() {
    super.initState();
    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_9GSIOVrscIpH7WlH9p5donv100k7On42UV",
        merchantId: "AdviceBee",
        androidPayMode: 'test'));
  }

  void setError(dynamic error) {
    _scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text(_error.toString())));
    setState(() {
      _error = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Payment History'),
        leading: MaterialButton(
          minWidth: MediaQuery.of(context).size.width / 5,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ));
            if (CurrentUser.isNotGuest) {
            } else {
              guestUserSignInMessage(context);
            }
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _generateReportsCategoryReason(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _generateReportsCategoryReason() {
    List<DataRow> history = List();
    String reasons = "";
    String priceCard = "";
    String lastFourCard = "";
    return StreamBuilder(
        stream: Firestore.instance.collection('cards').document(CurrentUser.userID).collection('purchaseHistory').orderBy('date').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            snapshot.data.documents.forEach((e) {
              reasons = (e.data["itemPurchased"]);
              priceCard = (e.data["itemCost"]);
              lastFourCard = (e.data["lastFour"]);
              history.add(DataRow(
                  cells: [
                    DataCell(
                      Text(
                        reasons,
                      ),
                    ),
                    DataCell(
                      Text(
                        priceCard,
                      ),
                    ),
                    DataCell(
                      Text(
                      lastFourCard,
                    ),
                    ),
              ]));
            });
            return Container(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Purchase Detail')),
                  DataColumn(label: Text('Cost')),
                  DataColumn(label: Text('Payment Method')),
                ],
                rows: history,
              ),
            );
          }
          else {
            return Text("Loading report category...");
          }
        }
    );
  }


  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }
}
