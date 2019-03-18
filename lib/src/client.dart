import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

const currencies = ["EUR", "CHF", "BTC"];

class Client {
  /// Used to send an appropriate User-Agent header with the HTTP requests.
  static const String _userAgent = 'Bity - Dart';
  static const String _mediaType = 'application/json';

  static const String _apiPrefix = '/api/v2';
  static const String _estimatePath = _apiPrefix + '/orders/estimate';
  static const String _createOrderPath = _apiPrefix + '/orders/phone';
  static const String _orderPath = _apiPrefix + '/orders/';

  static const _headers = {
    HttpHeaders.userAgentHeader: _userAgent,
    HttpHeaders.acceptHeader: _mediaType,
    HttpHeaders.contentTypeHeader: _mediaType,
  };

  /// The URL of the Bity server.
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

  /// Estimate how much output currency a specific amount of input currency would yield
  ///
  /// Throws a [UnsupportedCurrency] if either of the currencies is unsupported.
  Future<double> estimate(
      {String inputCurrency, double inputAmount, String outputCurrency}) async {
    _anyUnsupportedCurrencies(inputCurrency, outputCurrency);

    var requestUrl = url.replace(path: _estimatePath);
    var requestBody = json.encode({
      "input": {"currency": inputCurrency, "amount": inputAmount},
      "output": {"currency": outputCurrency}
    });

    var response = await _httpClient.post(
      requestUrl,
      body: requestBody,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return double.parse(jsonResponse["output"]["amount"]);
    }

    throw FailedHttpRequest(requestUrl, requestBody, response);
  }

  /// Create an order by specifying the crypto in which payment will be made and the *desired* to-be-paid amount in fiat.
  ///
  /// Throws a [UnsupportedCurrency] if either of the currencies is unsupported.
  Future<String> createCryptoToFiatOrder(
      {String inputCurrency,
      double outputAmount,
      String outputCurrency,
      String outputIban}) async {
    _anyUnsupportedCurrencies(inputCurrency, outputCurrency);

    var requestUrl = url.replace(path: _createOrderPath);

    var input = {
      "currency": inputCurrency,
      "type": "crypto_address",
    };
    var output = {
      "currency": outputCurrency,
      "type": "bank_address",
      "amount": outputAmount,
      "iban": outputIban,
    };
    var requestBody = json.encode({"input": input, "output": output});

    var response = await _httpClient.post(
      requestUrl,
      body: requestBody,
      headers: _headers,
    );

    if (response.statusCode == 201) {
      return response.headers[HttpHeaders.locationHeader];
    }

    throw FailedHttpRequest(requestUrl, requestBody, response);
  }

  /// Returns an order identified by a UUID
  Future<Map<String, dynamic>> getOrder(String uuid) async {
    var requestUrl = url.replace(path: _orderPath + uuid);

    var response = await _httpClient.get(
      requestUrl,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    throw FailedHttpRequest(requestUrl, '', response);
  }

  void _anyUnsupportedCurrencies(inputCurrency, outputCurrency) {
    if (_isUnsupportedCurrency(inputCurrency)) {
      throw UnsupportedCurrency(currencies, inputCurrency);
    }

    if (_isUnsupportedCurrency(outputCurrency)) {
      throw UnsupportedCurrency(currencies, outputCurrency);
    }
  }

  bool _isUnsupportedCurrency(currency) {
    return !currencies.contains(currency);
  }

  @override
  String toString() => "Client(url: $url)";
}
