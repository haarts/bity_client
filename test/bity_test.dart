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
var owner = Owner(
  "Some street",
  "Some city",
  "Some zip",
  "Some country",
  "Some name",
);

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

  group("getEstimate()", () {
    test("rejects unsupported currencies", () {
      expect(
          () => client.getEstimate(
              inputCurrency: "FOO",
              inputAmount: inputAmount,
              outputCurrency: outputCurrency),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
      expect(
          () => client.getEstimate(
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
          "amount": "1.00000000",
          "minimum_amount": "0.00100000"
        },
        "output": {
          "currency": "EUR",
          "amount": "$outputAmount"
        }
      }
      ''');

      var result = await client.getEstimate(
          inputCurrency: inputCurrency,
          inputAmount: inputAmount,
          outputCurrency: outputCurrency);

      var request = server.takeRequest();
      expect(request.uri.path, '/v2/orders/estimate');
      expect(request.method, 'POST');
      expect(result, equals(outputAmount));
    });

    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.getEstimate(
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
                outputIban: iban,
                owner: owner,
              ),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));

      expect(
          () => client.createCryptoToFiatOrder(
                inputCurrency: inputCurrency,
                outputAmount: outputAmount,
                outputCurrency: "BAR",
                outputIban: iban,
                owner: owner,
              ),
          throwsA(const TypeMatcher<UnsupportedCurrency>()));
    });

    test("throws a OrderAmountTooLow exception", () async {
      server.enqueue(
        httpCode: 400,
        body: File('test/files/order_amount_too_low.json').readAsStringSync(),
      );

      expect(
        () => client.createCryptoToFiatOrder(
              inputCurrency: inputCurrency,
              outputAmount: outputAmount,
              outputCurrency: outputCurrency,
              outputIban: iban,
              owner: owner,
            ),
        throwsA(TypeMatcher<OrderAmountTooLow>()),
      );
    });

    test("throws a generic exception", () async {
      server.enqueue(
          httpCode: 400, body: '{"errors": [{"code": "some_code"}]}');

      expect(
          () => client.createCryptoToFiatOrder(
                inputCurrency: inputCurrency,
                outputAmount: outputAmount,
                outputCurrency: outputCurrency,
                outputIban: iban,
                owner: owner,
              ),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });

    test("throws an exception when the owner is invalid/unknown", () async {
      var cannedResponse =
          await File('test/files/invalid_bank_address.json').readAsString();
      server.enqueue(httpCode: 400, body: cannedResponse);

      expect(
          () => client.createCryptoToFiatOrder(
                inputCurrency: inputCurrency,
                outputAmount: outputAmount,
                outputCurrency: outputCurrency,
                outputIban: iban,
                owner: Owner("", "", "", "", ""),
              ),
          throwsA(TypeMatcher<InvalidBankAddress>()
              .having((e) => e.toString(), "toString()", contains(''))));
    });

    test("return a URL pointing to the created order", () async {
      const someUrl =
          "https://exchange.api.bity.com/v2/orders/420cb74c-f347-4460-b085-13641ad74525";
      server.enqueue(
          httpCode: 201, headers: {HttpHeaders.locationHeader: someUrl});

      var result = await client.createCryptoToFiatOrder(
        inputCurrency: inputCurrency,
        outputAmount: outputAmount,
        outputCurrency: outputCurrency,
        outputIban: iban,
        owner: owner,
      );

      var request = server.takeRequest();
      expect(request.uri.path, '/v2/orders');
      expect(request.method, 'POST');
      expect(request.headers[HttpHeaders.cookieHeader], isNull);
      expect(
        request.body,
        equals(
            '{"input":{"currency":"BTC","type":"crypto_address"},"output":{"currency":"EUR","type":"bank_account","amount":"20.3","iban":"AT611904300234573201","owner":{"address":"Some street","country":"Some country","city":"Some city","zip":"Some zip","name":"Some name"}}}'),
      );
      expect(result, equals(someUrl));
    });

    test("client sends a session cookie when present", () async {
      var sessionValue = "session=first";

      // Setup first response
      server.enqueue(
        httpCode: 201,
        headers: {
          HttpHeaders.setCookieHeader: sessionValue,
        },
      );
      // This sets the session
      await client.createCryptoToFiatOrder(
        inputCurrency: inputCurrency,
        outputAmount: outputAmount,
        outputCurrency: outputCurrency,
        outputIban: iban,
        owner: owner,
      );
      // Not interested in the first request
      server.takeRequest();

      // Setup second response
      server.enqueue(
        httpCode: 201,
        headers: {
          HttpHeaders.setCookieHeader: "session=second",
        },
      );

      // This request SHOULD pass the session value received from the first
      // request
      await client.createCryptoToFiatOrder(
        inputCurrency: inputCurrency,
        outputAmount: outputAmount,
        outputCurrency: outputCurrency,
        outputIban: iban,
        owner: owner,
      );

      var request = server.takeRequest();
      expect(request.headers[HttpHeaders.cookieHeader], sessionValue);
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
      expect(response, TypeMatcher<Order>());

      var request = server.takeRequest();
      expect(request.uri.path, '/v2/orders/0123456789abcdefghijk');
      expect(request.method, 'GET');
    });
  });

  test("Order.fromJson()", () async {
    var jsonString = await File('test/files/order.json').readAsString();

    Order order = Order.fromJson(json.decode(jsonString));

    expect(order.id, "5ceea32c-418b-4fa5-af8f-9e270ec19acf");

    PaymentDetails paymentDetails = order.paymentDetails;

    expect(paymentDetails.type, "crypto_address");
    expect(paymentDetails.cryptoAddress, "3Qaur9qYjEYtuLiwZNxvh4LzeMn54aALZX");
    expect(paymentDetails.bankAccount, null);

    Input input = order.input;

    expect(input.amount, 0.11450327);

    Output output = order.output;

    expect(output.amount, 900.0);
    expect(output.iban, "CH3600000000000000000");
  });

  group("getOrders()", () {
    test("returns a sane error message", () async {
      server.enqueue(httpCode: 400);

      expect(
          () => client.getOrders(),
          throwsA(TypeMatcher<FailedHttpRequest>()
              .having((e) => e.toString(), "toString()", contains('400'))));
    });

    test("returns the orders", () async {
      var cannedResponse = await File('test/files/orders.json').readAsString();
      server.enqueue(httpCode: 200, body: cannedResponse);

      var response = await client.getOrders();
      expect(response, TypeMatcher<List<Order>>());
      expect(response, hasLength(1));

      var request = server.takeRequest();
      expect(request.uri.path, '/v2/orders');
      expect(request.method, 'GET');
    });
  });

  group("getCurrencies()", () {
    test("returns the currencies", () async {
      var cannedResponse =
          await File('test/files/currencies.json').readAsString();
      server.enqueue(httpCode: 200, body: cannedResponse);

      var response = await client.getCurrencies();
      expect(response, TypeMatcher<List<String>>());
      expect(response, hasLength(5));

      var request = server.takeRequest();
      expect(request.uri.path, '/v2/currencies');
      expect(request.method, 'GET');
    });
  });
}
