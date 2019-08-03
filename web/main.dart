@JS()
library bity;

import 'package:js/js.dart';
import 'package:bity/bity.dart';

@JS()
class Promise<T> {
  external Promise(void executor(void resolve(T result), Function reject));
  external Promise then(void onFulfilled(T result), [Function onRejected]);
}

/// Converts a function returning a dart Future to a function returning
/// a javascript Promise.
/// Due to lack of variadic templates this implements support for unary
/// functions.
Promise<T> Function(P) future2Promise<T, P>(Future<T> Function(P) f) {
  return (P p) => Promise<T>(
      allowInterop((resolve, reject) => f(p).then(resolve, onError: reject)));
}

@JS()
@anonymous
class JsOwner {
  external String get street;
  external String get city;
  external String get zip;
  external String get country;
  external String get name;
}

@JS()
@anonymous
class Details {
  external JsOwner get owner;
  external double get outputAmount;
  external String get outputIBAN;
  external String get reference;
}

@JS()
@anonymous
class JsOrder {
  external factory JsOrder({double inputAmount, String cryptoAddress});
}

@JS('createOrder')
external set _createOrder(Promise<JsOrder> Function(Details) f);

Future<JsOrder> _createAsyncOrder(Details details) async {
  final client = Client('https://exchange.api.bity.com/');
  final owner = Owner(details.owner.street, details.owner.city,
      details.owner.zip, details.owner.country, details.owner.name);
  String orderURL = await client.createCryptoToFiatOrder(
    inputCurrency: "BTC",
    outputAmount: details.outputAmount,
    outputCurrency: "CHF",
    outputIban: details.outputIBAN,
    owner: owner,
    reference: details.reference,
  );

  Order order = await client.getOrder(orderURL.split('/').last);
  client.close();
  return JsOrder(
      inputAmount: order.input.amount,
      cryptoAddress: order.paymentDetails.cryptoAddress);
}

void main() {
  _createOrder = allowInterop(future2Promise(_createAsyncOrder));
}
