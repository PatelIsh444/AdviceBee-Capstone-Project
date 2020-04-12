
import 'package:credit_card/credit_card_form.dart';
import 'package:credit_card/credit_card_model.dart';
import 'package:credit_card/credit_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';

import 'package:v0/services/PaymentService.dart';
import 'package:v0/utils/commonFunctions.dart';

import '../Dashboard.dart';
import 'PaymentHistory.dart';

class PaymentConfirm extends StatefulWidget {
  @override
  _PaymentConfirmState createState() => new _PaymentConfirmState();
}

class _PaymentConfirmState extends State<PaymentConfirm> {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  String _error = 'Pending...';
  Source _source;

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
        title: Text('Payment Confirmation'),
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
      body: ListView(
        children: <Widget>[
          Center(

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(30.0),
                ),
                Text("Your Payment has been processed successfull!",
                    textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 40,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: <Color>[
                        Colors.green,
                        Colors.redAccent,
                      ],
                    ). createShader(Rect.fromLTWH(0.0, 0.0, 300.0, 100.0))
              )
                ),
                 Padding(
                   padding: EdgeInsets.all(75.0),
                ),
                RaisedButton(
                  padding: EdgeInsets.all(20.0),
                  color: Colors.green,

                  child: Text(
                    "Payment History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentHistory(),
                        ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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
