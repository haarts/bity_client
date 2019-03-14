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
const iban = "some iban";
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
      expect(() => client.estimate("FOO", inputAmount, outputCurrency),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
      expect(() => client.estimate(inputCurrency, inputAmount, "BAR"),
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

      var result =
          await client.estimate(inputCurrency, inputAmount, outputCurrency);

      expect(server.takeRequest().uri.path, '/orders/estimate');
      expect(result, equals(outputAmount));
    });

    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.estimate(inputCurrency, inputAmount, outputCurrency),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });
  });

  group("createCryptoToFiatOrder()", () {
    test("rejects unsupported currencies", () async {
      expect(
          () => client.createCryptoToFiatOrder(
              "FOO", inputAmount, outputCurrency, iban),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
      expect(
          () => client.createCryptoToFiatOrder(
              inputCurrency, inputAmount, "BAR", iban),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
    });

    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.createCryptoToFiatOrder(
              inputCurrency, inputAmount, outputCurrency, iban),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });

    test("return a URL pointing to the created order", () async {
      const someUrl =
          "https://bity.com/api/v2/orders/420cb74c-f347-4460-b085-13641ad74525";
      server.enqueue(
          httpCode: 201, headers: {HttpHeaders.locationHeader: someUrl});

      var result = await client.createCryptoToFiatOrder(
          inputCurrency, outputAmount, outputCurrency, iban);

      var request = server.takeRequest();

      expect(request.uri.path, '/orders/phone');
      expect(
          request.body,
          equals(
              '{"input":{"currency":"BTC","type":"crypto_address"},"output":{"currency":"EUR","type":"bank_address","amount":20.3,"iban":"some iban"}}'));
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
      expect(response, TypeMatcher<Map<String, dynamic>>());
      expect(request.uri.path, '/orders/0123456789abcdefghijk');
      expect(request.method, 'GET');
    });
  });
}
