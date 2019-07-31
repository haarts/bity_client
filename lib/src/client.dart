import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' show Response;
import 'package:iban/iban.dart';

import 'package:http/http.dart' if (dart.library.js) 'browser_client.dart' as http;
import 'exceptions.dart';
import 'order.dart';
import 'owner.dart';

// TODO split this in crypto and fiat, then the checks can be more specific.
const currencies = ["EUR", "CHF", "BTC"];

class Client {
  /// Used to send an appropriate User-Agent header with the HTTP requests.
  static const String _userAgent = 'Bity - Dart';
  static const String _mediaType = 'application/json';

  static const String _apiPrefix = '/v2';
  static const String _estimatePath = _apiPrefix + '/orders/estimate';
  static const String _createOrderPath = _apiPrefix + '/orders';
  static const String _ordersPath = _apiPrefix + '/orders';
  static const String _currenciesPath = _apiPrefix + '/currencies';

  static const _headers = {
    HttpHeaders.userAgentHeader: _userAgent,
    HttpHeaders.acceptHeader: _mediaType,
    HttpHeaders.contentTypeHeader: _mediaType,
  };

  /// The URL of the Bity server.
  Uri url;

  http.Client _httpClient;

  Cookie _session;

  /// Create a new Bity client. Only the domain should be passed (the path is
  /// stripped).
  Client(String url) {
    _httpClient = http.Client();
    this.url = Uri.parse(url).replace(path: "");
  }

  /// Close the client when done.
  void close() {
    _httpClient.close();
  }

  /// Estimate how much output currency a specific amount of input currency would yield
  ///
  /// Throws a [UnsupportedCurrency] if either of the currencies is unsupported.
  Future<double> getEstimate(
      {String inputCurrency, double inputAmount, String outputCurrency}) async {
    _anyUnsupportedCurrencies(inputCurrency, outputCurrency);

    var requestUrl = url.replace(path: _estimatePath);
    var requestBody = json.encode({
      "input": {"currency": inputCurrency, "amount": inputAmount.toString()},
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
  Future<String> createCryptoToFiatOrder({
    String inputCurrency,
    double outputAmount,
    String outputCurrency,
    String outputIban,
    Owner owner,
    String reference,
  }) async {
    _anyUnsupportedCurrencies(inputCurrency, outputCurrency);
    _validateIban(outputIban);

    var requestUrl = url.replace(path: _createOrderPath);

    var input = {
      "currency": inputCurrency,
      "type": "crypto_address",
    };
    var output = {
      "currency": outputCurrency,
      "type": "bank_account",
      "amount": outputAmount.toString(),
      "iban": outputIban,
      "owner": owner,
    };
    if (reference != null) {
      output["reference"] = reference;
    }

    var requestBody = json.encode({"input": input, "output": output});

    var headers = Map<String, String>.from(_headers);
    if (_session != null) {
      headers..[HttpHeaders.cookieHeader] = _session.toString();
    }

    var response = await _httpClient.post(
      requestUrl,
      body: requestBody,
      headers: headers,
    );

    if (response.statusCode == 201) {
      _setSession(response);

      return response.headers[HttpHeaders.locationHeader];
    }

    var errors = json.decode(response.body)["errors"];
    if (errors[0]["code"] == InvalidBankAddress.remoteErrorCode) {
      throw InvalidBankAddress(owner.toString(), errors[0]["message"]);
    } else if (errors[0]["code"] == QuotaExceeded.remoteErrorCode) {
      throw QuotaExceeded(owner.toString(), errors[0]["message"]);
    } else if (errors[0]["code"] == OrderAmountTooLow.remoteErrorCode) {
      throw OrderAmountTooLow(errors[0]["message"]);
    }

    throw FailedHttpRequest(requestUrl, requestBody, response);
  }

  /// Returns an order identified by a UUID
  Future<Order> getOrder(String uuid) async {
    var requestUrl = url.replace(path: _ordersPath + "/" + uuid);

    var response = await _httpClient.get(
      requestUrl,
      headers: Map.from(_headers)
        ..[HttpHeaders.cookieHeader] = _session.toString(),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    }

    throw FailedHttpRequest(requestUrl, '', response);
  }

  Future<List<Order>> getOrders() async {
    var requestUrl = url.replace(path: _ordersPath);

    var response = await _httpClient.get(
      requestUrl,
      headers: Map.from(_headers)
        ..[HttpHeaders.cookieHeader] = _session.toString(),
    );

    if (response.statusCode == 200) {
      var jsonOrders = json.decode(response.body);
      return jsonOrders["orders"]
          .map<Order>((order) => Order.fromJson(order))
          .toList();
    }

    throw FailedHttpRequest(requestUrl, '', response);
  }

  Future<List<String>> getFiatCurrencies() async {
    return getCurrencies("fiat");
  }

  Future<List<String>> getCryptoCurrencies() async {
    return getCurrencies("crypto");
  }

  Future<List<String>> getCurrencies([String filter]) async {
    String tags = "";
    if (filter != null) {
      tags = "?tags=$filter";
    }
    var requestUrl = url.toString() + _currenciesPath + tags;

    var response = await _httpClient.get(
      requestUrl,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      var jsonCurrencies = json.decode(response.body);
      return jsonCurrencies["currencies"]
          .map<String>((currency) => currency["code"] as String)
          .toList();
    }

    throw FailedHttpRequest(Uri.parse(requestUrl), '', response);
  }

  void _setSession(Response response) {
    String cookie = response.headers[HttpHeaders.setCookieHeader];
    if (cookie != null) {
      _session = Cookie.fromSetCookieValue(cookie);
    }
  }

  void _validateIban(String iban) {
    if (!isValid(iban)) {
      throw InvalidIban(iban);
    }
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
