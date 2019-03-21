import 'package:bity/bity.dart';

void main() async {
  var client = Client('https://bity.com/');
  var estimate = await client.estimate(
      inputCurrency: "BTC", inputAmount: 1, outputCurrency: "CHF").timeout(const Duration(seconds: 2));
  print('1 BTC costs $estimate CHF');

  var orders = await client.getOrders();
  print('Orders: $orders');
  client.close();
}
