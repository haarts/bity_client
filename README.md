# Bity library

[![pub package](https://img.shields.io/pub/v/bity.svg)](https://pub.dartlang.org/packages/bity)

A library for communicating with the [Bity API]. Some calls are missing.

## Examples

### Get an estimate
```dart
  var client = Client('https://exchange.api.bity.com/');
  print(await client.estimate(inputCurrency: "BTC", inputAmount: 1, outputCurrency: "CHF"));
  client.close();
```

### Create a crypto to fiat order
In this example you want to buy 1000 CHF for Ether. How much Ether that
is going to cost can be found by looking at the generated order.

```dart
  var client = Client('https://exchange.api.bity.com/');
  var uuid = await client.createCryptoToFiatOrder(inputCurrency: "ETH", outputCurrency: "CHF", outputAmount: 1000, outputIban: "some iban", "owner": {"name": "some name", "address": "some street", "zip": "some zip", "city": "some city", "country": "some country CODE!"}, "reference": "a reference"));
  print(uuid);
  client.close();
```

### View order

```dart
  var client = Client('https://exchange.api.bity.com/');
  print(await client.getOrder("some uuid"));
  client.close();
```

## Installing

Add it to your `pubspec.yaml`:

```
dependencies:
  bity: any
```

## Licence overview

All files in this repository fall under the license specified in
[COPYING](COPYING). The project is licensed as [AGPL with a lesser clause](https://www.gnu.org/licenses/agpl-3.0.en.html). 
It may be used within a proprietary project, but the core library and any 
changes to it must be published online. Source code for this library must 
always remain free for everybody to access.

## Thanks

[Bity API]: https://doc.bity.com/exchange/v2.html
