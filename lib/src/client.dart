import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

const currencies = ["EUR", "CHF", "BTC"];

class Client {
  /// Used to send an appropriate User-Agent header with the HTTP requests.
  static const String _userAgent = 'Bity - Dart';
  static const String _mediaType = 'application/json';

  static const _headers = {
    HttpHeaders.userAgentHeader: _userAgent,
    HttpHeaders.acceptHeader: _mediaType,
    HttpHeaders.contentTypeHeader: _mediaType,
  };

  /// The URL of the BTCPay server.
  Uri url;

  http.Client _httpClient;

  Client(String url) {
    _httpClient = http.Client();
    this.url = Uri.parse(url);
  }

  /// Close the client when done.
  void close() {
    _httpClient.close();
  }

  Future<double> estimate(
      String inputCurrency, double inputAmount, String outputCurrency) async {
    if (_isUnsupportedCurrency(inputCurrency)) {
      throw UnsupportedCurrency(currencies, inputCurrency);
    }

    if (_isUnsupportedCurrency(outputCurrency)) {
      throw UnsupportedCurrency(currencies, outputCurrency);
    }

    var requestUrl = url.replace(path: '/orders/estimate');
    var requestBody = json.encode({
      "input": {"currency": inputCurrency, "amount": inputAmount},
      "output": {"currency": outputCurrency}
    });

    var response = await _httpClient.post(requestUrl,
        body: requestBody, headers: _headers);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return double.parse(jsonResponse["output"]["amount"]);
    }

    throw FailedHttpRequest(requestUrl, requestBody, response);
  }

  bool _isUnsupportedCurrency(currency) {
    return !currencies.contains(currency);
  }

  @override
  String toString() => "Client(url: $url)";
}
