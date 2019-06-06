import 'package:bity/bity.dart';

void main() async {
  var client = Client('https://exchange.api.bity.com/');
  var estimate = await client
      .getEstimate(inputCurrency: "BTC", inputAmount: 1, outputCurrency: "CHF")
      .timeout(const Duration(seconds: 2));
  print('1 BTC costs $estimate CHF');

  var owner = Owner(
    "Some street",
    "Some city",
    "Some zip",
    "CH",
    "Some name",
  );
  await client.createCryptoToFiatOrder(
    inputCurrency: "BTC",
    outputAmount: 10.0,
    outputCurrency: "CHF",
    outputIban: "AT611904300234573201",
    owner: owner,
  );
  var orders = await client.getOrders();
  print('Orders: $orders');
  client.close();
}
