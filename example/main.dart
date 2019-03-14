import 'package:bity/bity.dart';

void main() async {
  var client = Client('https://bity.com/');
  var output = await client.estimate(
      inputCurrency: "BTC", inputAmount: 1, outputCurrency: "CHF");
  print('1 BTC costs $output CHF');
  client.close();
}
