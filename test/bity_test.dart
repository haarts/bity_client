import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import "package:mock_web_server/mock_web_server.dart";

import "package:bity/bity.dart";

MockWebServer server;
Client client;

const inputCurrency = "BTC";
const inputAmount = 1.0;
const outputCurrency = "EUR";
const outputAmount = 20.3;
const iban = "AT611904300234573201";
const someUuid = "0123456789abcdefghijk";

void main() {
  setUp(() async {
    server = MockWebServer();
    await server.start();
    client = Client(server.url);
  });

  tearDown(() async {
    server.shutdown();
  });

  test("initialize", () {
    expect(client, isNotNull);
    expect(client.url.host, "127.0.0.1");
  });

  group("estimate()", () {
    test("rejects unsupported currencies", () {
      expect(
          () => client.estimate(
              inputCurrency: "FOO",
              inputAmount: inputAmount,
              outputCurrency: outputCurrency),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
      expect(
          () => client.estimate(
              inputCurrency: inputCurrency,
              inputAmount: inputAmount,
              outputCurrency: "BAR"),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
    });

    test("returns double", () async {
      const outputAmount = 3087.86;
      server.enqueue(body: '''
       {
        "input": {
          "currency": "BTC",
          "amount": "1.00000000"
        },
        "output": {
          "currency": "EUR",
          "amount": "$outputAmount"
        }
      }
      ''');

      var result = await client.estimate(
          inputCurrency: inputCurrency,
          inputAmount: inputAmount,
          outputCurrency: outputCurrency);

      var request = server.takeRequest();
      expect(request.uri.path, '/api/v2/orders/estimate');
      expect(request.method, 'POST');
      expect(result, equals(outputAmount));
    });

    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.estimate(
              inputCurrency: inputCurrency,
              inputAmount: inputAmount,
              outputCurrency: outputCurrency),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });
  });

  group("createCryptoToFiatOrder()", () {
    test("rejects unsupported currencies", () async {
      expect(
          () => client.createCryptoToFiatOrder(
              inputCurrency: "FOO",
              outputAmount: outputAmount,
              outputCurrency: outputCurrency,
              outputIban: iban),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
      expect(
          () => client.createCryptoToFiatOrder(
              inputCurrency: inputCurrency,
              outputAmount: outputAmount,
              outputCurrency: "BAR",
              outputIban: iban),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
    });

    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.createCryptoToFiatOrder(
              inputCurrency: inputCurrency,
              outputAmount: outputAmount,
              outputCurrency: outputCurrency,
              outputIban: iban),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });

    test("return a URL pointing to the created order", () async {
      const someUrl =
          "https://bity.com/api/v2/orders/420cb74c-f347-4460-b085-13641ad74525";
      server.enqueue(
          httpCode: 201, headers: {HttpHeaders.locationHeader: someUrl});

      var result = await client.createCryptoToFiatOrder(
          inputCurrency: inputCurrency,
          outputAmount: outputAmount,
          outputCurrency: outputCurrency,
          outputIban: iban);

      var request = server.takeRequest();
      expect(request.uri.path, '/api/v2/orders/phone');
      expect(request.method, 'POST');
      expect(
          request.body,
          equals(
              '{"input":{"currency":"BTC","type":"crypto_address"},"output":{"currency":"EUR","type":"bank_address","amount":20.3,"iban":"AT611904300234573201"}}'));
      expect(result, equals(someUrl));
    });
  });

  group("getOrder()", () {
    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.getOrder(someUuid),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });

    test("returns the order", () async {
      var cannedResponse = await File('test/files/order.json').readAsString();
      server.enqueue(httpCode: 200, body: cannedResponse);

      var response = await client.getOrder(someUuid);

      var request = server.takeRequest();
      expect(response, TypeMatcher<Order>());
      expect(request.uri.path, '/api/v2/orders/0123456789abcdefghijk');
      expect(request.method, 'GET');
    });
  });

  test("Order.fromJson()", () async {
    var jsonString = await File('test/files/order.json').readAsString();

    Order order = Order.fromJson(json.decode(jsonString));

    expect(order.id, "0123456789abcdefghijk");

    PaymentDetails paymentDetails = order.paymentDetails;

    expect(paymentDetails.type, "crypto_address");
    expect(paymentDetails.cryptoAddress,
        "0xf35074bbd0a9aee46f4ea137971feec024ab7048");
    expect(paymentDetails.bankAccount, null);

    Input input = order.input;

    expect(input.amount, 0.5);

    Output output = order.output;

    expect(output.amount, 104.95);
    expect(output.iban, "CH3600000000000000000");
  });
}
