import 'package:credit_card/credit_card_form.dart';
import 'package:credit_card/credit_card_model.dart';
import 'package:credit_card/credit_card_widget.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:v0/pages/PaymentConfirm.dart';

import 'package:v0/services/PaymentService.dart';
import 'package:v0/utils/commonFunctions.dart';

import '../Dashboard.dart';
import '../MoreMenu.dart';
import '../QuestionPage.dart';

class BuyMoreQuestions extends StatefulWidget {
  @override
  _BuyMoreQuestionsState createState() => new _BuyMoreQuestionsState();
}

class _BuyMoreQuestionsState extends State<BuyMoreQuestions> {
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
  GlobalKey key = GlobalKey();

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
    Flushbar(
      title: _error.toString(),
      message: " ",
      duration: Duration(seconds: 5),
      backgroundColor: Colors.teal,
    ).show(context);
//    _scaffoldKey.currentState
//        .showSnackBar(SnackBar(content: Text(_error.toString())));
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
            Navigator.pop(context);
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
          Expanded(
            child: CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView:
                  isCvvFocused, //true when you want to show cvv(back) view
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: CreditCardForm(
                onCreditCardModelChange: onCreditCardModelChange,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RaisedButton(
                  color: Colors.green,
                  child: Text(
                    "Buy More Questions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                  onPressed: () {
                    cardMonth = int.parse(expiryDate.split('/')[0]);
                    cardYear = int.parse(expiryDate.split('/')[1]);
                    final CreditCard paymentCard = CreditCard(
                      number: cardNumber,
                      expMonth: cardMonth,
                      expYear: cardYear,
                    );
                    StripePayment.createTokenWithCard(
                      paymentCard,
                    ).then((token) {
                      _scaffoldKey.currentState.showSnackBar(
                          SnackBar(content: Text('Received ${token.tokenId}')));
                      setState(() {
                        _paymentToken = token;
                      });
                      paymentService.addUserCard(token);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentConfirm(),
                          ));
                    }).catchError(setError);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (CurrentUser.isNotGuest) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => postQuestion(null, null) //AddPost(),
                    ));
          } else {
            guestUserSignInMessage(context);
          }
        },
        heroTag: "my2PostsHero",
        tooltip: 'Increment',
        child: CircleAvatar(
          child: Image.asset(
            'images/addPostIcon4.png',
          ),
          maxRadius: 12,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: globalNavigationBar(2, context, key, false),
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
