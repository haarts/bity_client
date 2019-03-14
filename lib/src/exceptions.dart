import 'package:http/http.dart' as http;

class UnsupportedCurrency implements Exception {
  UnsupportedCurrency(this.supportedCurrencies, this.providedCurrency);
  String providedCurrency;
  List<String> supportedCurrencies;

  String toString() =>
      "'$providedCurrency' is not a valid currency: $supportedCurrencies";
}

class FailedHttpRequest implements Exception {
  FailedHttpRequest(this.requestUrl, this.requestBody, this.response);
  Uri requestUrl;
  String requestBody;
  http.Response response;

  String toString() {
    return '''
    	Request URL: $requestUrl,
    	Request Body: $requestBody,
    	Response Status code: ${response.statusCode},
    	Response Body: ${response.body}
    ''';
  }
}
