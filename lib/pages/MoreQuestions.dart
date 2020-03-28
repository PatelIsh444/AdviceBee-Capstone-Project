import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'dart:io';

import 'package:v0/services/PaymentService.dart';

class BuyMoreQuestions extends StatefulWidget {
  @override
  _BuyMoreQuestionsState createState() => new _BuyMoreQuestionsState();
}

class _BuyMoreQuestionsState extends State<BuyMoreQuestions> {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  String _error = "Pending...";
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

  @override
  initState() {
    super.initState();
    StripePayment.setOptions(
        StripeOptions(publishableKey: "pk_test_9GSIOVrscIpH7WlH9p5donv100k7On42UV", merchantId: "AdviceBee", androidPayMode: 'test'));
    StripePayment.createSourceWithParams(SourceParams(
      type: 'AdviceBeePro',
      amount: 0099,
      currency: 'usd',
      returnURL: 'example://stripe-redirect',
    )).then((source) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Received ${source.sourceId}')));
      setState(() {
        _source = source;
      });
    }).catchError(setError);
  }

  void setError(dynamic error) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(error.toString())));
    setState(() {
      _error = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        key: _scaffoldKey,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              color: Colors.green,
              child: Text("Add Card", style: TextStyle(color: Colors.white),),
              onPressed: () {
                StripePayment.paymentRequestWithCardForm(CardFormPaymentRequest()).then((paymentMethod) {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Received ${paymentMethod.id}')));
                  setState(() {
                    CreditCardForm();
                    _paymentMethod = paymentMethod;
                    paymentService.addUserCard(_paymentMethod);
                  });
                }).catchError(setError);
              },
            ),
            Divider(),
            Text('Status: $_error'),
          ],
        ),
      ),
    );
  }
}
//import 'dart:async';
//import 'dart:io';
//import 'package:flutter/material.dart';
//import 'package:in_app_purchase/in_app_purchase.dart';
//
//const bool kAutoConsume = true;
//
//const String _kConsumableId = 'add_more_questions';
//const List<String> _kProductIds = <String>[
//  _kConsumableId,
//];
//
//List<String> consumableItem = <String>[
//  'consumables'
//];
//
//class BuyMoreQuestions extends StatefulWidget {
//  createState() => BuyMoreQuestionsState();
//}
//
//class BuyMoreQuestionsState extends State<BuyMoreQuestions> {
//  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
//  StreamSubscription<List<PurchaseDetails>> _subscription;
//  List<String> _notFoundIds = [];
//  List<ProductDetails> _products = [];
//  List<PurchaseDetails> _purchases = [];
//  List<String> _consumables = [];
//  bool _isAvailable = false;
//  bool _purchasePending = false;
//  bool _loading = true;
//  String _queryProductError;
//  @override
//  void initState() {
//    Stream purchaseUpdated =
//        InAppPurchaseConnection.instance.purchaseUpdatedStream;
//    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
//      _listenToPurchaseUpdated(purchaseDetailsList);
//    }, onDone: () {
//      _subscription.cancel();
//    }, onError: (error) {
//      // handle error here.
//    });
//    initStoreInfo();
//    super.initState();
//  }
//  Future<void> initStoreInfo() async {
//    final bool isAvailable = await _connection.isAvailable();
//    if (!isAvailable) {
//      setState(() {
//        _isAvailable = isAvailable;
//        _products = [];
//        _purchases = [];
//        _notFoundIds = [];
//        _consumables = [];
//        _purchasePending = false;
//        _loading = false;
//      });
//      return;
//    }
//
//    ProductDetailsResponse productDetailResponse =
//    await _connection.queryProductDetails(_kProductIds.toSet());
//    if (productDetailResponse.error != null) {
//      setState(() {
//        _queryProductError = productDetailResponse.error.message;
//        _isAvailable = isAvailable;
//        _products = productDetailResponse.productDetails;
//        _purchases = [];
//        _notFoundIds = productDetailResponse.notFoundIDs;
//        _consumables = [];
//        _purchasePending = false;
//        _loading = false;
//      });
//      return;
//    }
//
//    if (productDetailResponse.productDetails.isEmpty) {
//      setState(() {
//        _queryProductError = null;
//        _isAvailable = isAvailable;
//        _products = productDetailResponse.productDetails;
//        _purchases = [];
//        _notFoundIds = productDetailResponse.notFoundIDs;
//        _consumables = [];
//        _purchasePending = false;
//        _loading = false;
//      });
//      return;
//    }
//
//    final QueryPurchaseDetailsResponse purchaseResponse =
//    await _connection.queryPastPurchases();
//    if (purchaseResponse.error != null) {
//      // handle query past purchase error..
//    }
//    final List<PurchaseDetails> verifiedPurchases = [];
//    for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
//      if (await _verifyPurchase(purchase)) {
//        verifiedPurchases.add(purchase);
//      }
//    }
//    List<String> consumables = consumableItem;
//    setState(() {
//      _isAvailable = isAvailable;
//      _products = productDetailResponse.productDetails;
//      _purchases = verifiedPurchases;
//      _notFoundIds = productDetailResponse.notFoundIDs;
//      _consumables = consumables;
//      _purchasePending = false;
//      _loading = false;
//    });
//  }
//
//  @override
//  void dispose() {
//    _subscription.cancel();
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    List<Widget> stack = [];
//    if (_queryProductError == null) {
//      stack.add(
//        ListView(
//          children: [
//            _buildConnectionCheckTile(),
//            _buildProductList(),
//            _buildConsumableBox(),
//          ],
//        ),
//      );
//    } else {
//      stack.add(Center(
//        child: Text(_queryProductError),
//      ));
//    }
//    if (_purchasePending) {
//      stack.add(
//        Stack(
//          children: [
//            Opacity(
//              opacity: 0.3,
//              child: const ModalBarrier(dismissible: false, color: Colors.grey),
//            ),
//            Center(
//              child: CircularProgressIndicator(),
//            ),
//          ],
//        ),
//      );
//    }
//
//    return MaterialApp(
//      home: Scaffold(
//        appBar: AppBar(
//          backgroundColor: Colors.teal,
//          title: const Text('AdviceBee Store'),
//        ),
//        body: Stack(
//          children: stack,
//        ),
//      ),
//    );
//  }
//
//  Card _buildConnectionCheckTile() {
//    if (_loading) {
//      return Card(child: ListTile(title: const Text('Trying to connect...')));
//    }
//    final Widget storeHeader = ListTile(
//      leading: Icon(_isAvailable ? Icons.check : Icons.block,
//          color: _isAvailable ? Colors.green : ThemeData.light().errorColor),
//      title: Text(
//          'The store is ' + (_isAvailable ? 'available' : 'unavailable') + '.'),
//    );
//    final List<Widget> children = <Widget>[storeHeader];
//
//    if (!_isAvailable) {
//      children.addAll([
//        Divider(),
//        ListTile(
//          title: Text('Not connected',
//              style: TextStyle(color: ThemeData.light().errorColor)),
//          subtitle: const Text(
//              'Unable to connect to the payments processor. Has this app been configured correctly? See the example README for instructions.'),
//        ),
//      ]);
//    }
//    return Card(child: Column(children: children));
//  }
//
//  Card _buildProductList() {
//    if (_loading) {
//      return Card(
//          child: (ListTile(
//              leading: CircularProgressIndicator(),
//              title: Text('Fetching products...'))));
//    }
//    if (!_isAvailable) {
//      return Card();
//    }
//    final ListTile productHeader = ListTile(title: Text('Products for Sale'));
//    List<ListTile> productList = <ListTile>[];
//    if (_notFoundIds.isNotEmpty) {
//      productList.add(ListTile(
//          title: Text('[${_notFoundIds.join(", ")}] not found',
//              style: TextStyle(color: ThemeData.light().errorColor)),
//          subtitle: Text(
//              'This app needs special configuration to run. Please see example/README.md for instructions.')));
//    }
//
//    // This loading previous purchases code is just a demo. Please do not use this as it is.
//    // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
//    // We recommend that you use your own server to verity the purchase data.
//    Map<String, PurchaseDetails> purchases =
//    Map.fromEntries(_purchases.map((PurchaseDetails purchase) {
//      if (purchase.pendingCompletePurchase) {
//        InAppPurchaseConnection.instance.completePurchase(purchase);
//      }
//      return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
//    }));
//    productList.addAll(_products.map(
//          (ProductDetails productDetails) {
//        PurchaseDetails previousPurchase = purchases[productDetails.id];
//        return ListTile(
//            title: Text(
//              productDetails.title,
//            ),
//            subtitle: Text(
//              productDetails.description,
//            ),
//            trailing: previousPurchase != null
//                ? Icon(Icons.check)
//                : FlatButton(
//              child: Text(productDetails.price),
//              color: Colors.green[800],
//              textColor: Colors.white,
//              onPressed: () {
//                PurchaseParam purchaseParam = PurchaseParam(
//                    productDetails: productDetails,
//                    applicationUserName: null,
//                    sandboxTesting: true);
//                if (productDetails.id == _kConsumableId) {
//                  _connection.buyConsumable(
//                      purchaseParam: purchaseParam,
//                      autoConsume: kAutoConsume || Platform.isIOS);
//                } else {
//                  _connection.buyNonConsumable(
//                      purchaseParam: purchaseParam);
//                }
//              },
//            ));
//      },
//    ));
//
//    return Card(
//        child:
//        Column(children: <Widget>[productHeader, Divider()] + productList));
//  }
//
//  Card _buildConsumableBox() {
//    if (_loading) {
//      return Card(
//          child: (ListTile(
//              leading: CircularProgressIndicator(),
//              title: Text('Fetching consumables...'))));
//    }
//    if (!_isAvailable || _notFoundIds.contains(_kConsumableId)) {
//      return Card();
//    }
//    final ListTile consumableHeader =
//    ListTile(title: Text('Purchased consumables'));
//    final List<Widget> tokens = _consumables.map((String id) {
//      return GridTile(
//        child: IconButton(
//          icon: Icon(
//            Icons.stars,
//            size: 42.0,
//            color: Colors.orange,
//          ),
//          splashColor: Colors.yellowAccent,
//          onPressed: () => consume(id),
//        ),
//      );
//    }).toList();
//    return Card(
//        child: Column(children: <Widget>[
//          consumableHeader,
//          Divider(),
//          GridView.count(
//            crossAxisCount: 5,
//            children: tokens,
//            shrinkWrap: true,
//            padding: EdgeInsets.all(16.0),
//          )
//        ]));
//  }
//
//  Future<void> consume(String id) async {
//    final List<String> consumables = consumableItem;
//    setState(() {
//      _consumables = consumables;
//    });
//  }
//
//  void showPendingUI() {
//    setState(() {
//      _purchasePending = true;
//    });
//  }
//
//  void deliverProduct(PurchaseDetails purchaseDetails) async {
//    // IMPORTANT!! Always verify a purchase purchase details before delivering the product.
//    if (purchaseDetails.productID == _kConsumableId) {
//      consumableItem.add(purchaseDetails.purchaseID);
//      List<String> consumables = consumableItem;
//      setState(() {
//        _purchasePending = false;
//        _consumables = consumables;
//      });
//    } else {
//      setState(() {
//        _purchases.add(purchaseDetails);
//        _purchasePending = false;
//      });
//    }
//  }
//
//  void handleError(IAPError error) {
//    setState(() {
//      _purchasePending = false;
//    });
//  }
//
//  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
//    // IMPORTANT!! Always verify a purchase before delivering the product.
//    // For the purpose of an example, we directly return true.
//    return Future<bool>.value(true);
//  }
//
//  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
//    // handle invalid purchase here if  _verifyPurchase` failed.
//  }
//
//  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
//    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
//      if (purchaseDetails.status == PurchaseStatus.pending) {
//        showPendingUI();
//      } else {
//        if (purchaseDetails.status == PurchaseStatus.error) {
//          handleError(purchaseDetails.error);
//        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
//          bool valid = await _verifyPurchase(purchaseDetails);
//          if (valid) {
//            deliverProduct(purchaseDetails);
//          } else {
//            _handleInvalidPurchase(purchaseDetails);
//            return;
//          }
//        }
//        if (Platform.isAndroid) {
//          if (!kAutoConsume && purchaseDetails.productID == _kConsumableId) {
//            await InAppPurchaseConnection.instance
//                .consumePurchase(purchaseDetails);
//          }
//        }
//        if (purchaseDetails.pendingCompletePurchase) {
//          await InAppPurchaseConnection.instance
//              .completePurchase(purchaseDetails);
//        }
//      }
//    });
//  }
//}