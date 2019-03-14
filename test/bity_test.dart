import 'package:test/test.dart';
import "package:mock_web_server/mock_web_server.dart";

import "package:bity/bity.dart";

MockWebServer server;
Client client;

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

  group("estimate", () {
    const inputCurrency = "EUR";
    const inputAmount = 1.0;
    const outputCurrency = "BTC";

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
}
