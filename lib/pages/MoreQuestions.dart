import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'dart:io';

import 'package:v0/services/PaymentService.dart';
import 'package:v0/utils/commonFunctions.dart';

import '../Dashboard.dart';
import '../MoreMenu.dart';

class BuyMoreQuestions extends StatefulWidget {
  @override
  _BuyMoreQuestionsState createState() => new _BuyMoreQuestionsState();
}

class _BuyMoreQuestionsState extends State<BuyMoreQuestions> {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  String _error = 'Pending...';
  final String _currentSecret = null; //set this yourself, e.g using curl
  PaymentIntentResult _paymentIntent;
  Source _source;

  var paymentService = new PaymentService();

  ScrollController _controller = ScrollController();

  CreditCard testCard = CreditCard(
    number: '4000002760003184',
    expMonth: 12,
    expYear: 21,
  );

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  get currentTab => null;

  @override
  initState() {
    super.initState();
    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_9GSIOVrscIpH7WlH9p5donv100k7On42UV",
        merchantId: "AdviceBee",
        androidPayMode: 'test'));
    StripePayment.createSourceWithParams(SourceParams(
      type: 'AdviceBeePro',
      amount: 0099,
      currency: 'usd',
      returnURL: 'example://stripe-redirect',
    )).then((source) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text('Received ${_source.sourceId}')));
      setState(() {
        _source = source;
      });
    }).catchError(setError);
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
        title: Text('Online Store'),
        leading: MaterialButton(
          minWidth: MediaQuery.of(context).size.width / 5,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dashboard(),
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
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RaisedButton(
            color: Colors.green,
            child: Text(
              "Add Card",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
              ),
            ),
            onPressed: () {
              StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest())
                  .then((paymentMethod) {
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(content: Text('Received ${paymentMethod.id}')));
                setState(() {
                  CreditCardForm();
                  _paymentMethod = paymentMethod;
                  paymentService.addUserCard(_paymentMethod);
                });
              }).catchError(setError);
            },
          ),
        ],
      )),
    );
  }
}
