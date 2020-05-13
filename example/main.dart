import 'package:bity/bity.dart';

// ignore_for_file: avoid_print
Future<void> main() async {
  var client = Client('https://exchange.api.bity.com/');
  var estimate = await client
      .getEstimate(inputCurrency: 'BTC', inputAmount: 1, outputCurrency: 'EUR')
      .timeout(const Duration(seconds: 2));
  print('1 BTC costs $estimate EUR');

  var owner = Owner(
    'Some street',
    'Some city',
    'Some zip',
    'AT',
    'Some name',
  );
  await client.createCryptoToFiatOrder(
    inputCurrency: 'BTC',
    outputAmount: 10,
    outputCurrency: 'EUR',
    outputIban: 'AT611904300234573201',
    owner: owner,
    reference: 'inapay',
  );
  var orders = await client.getOrders();
  print('Orders: $orders');
  client.close();
}
