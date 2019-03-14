import 'package:bity/bity.dart';

void main() async {
  var client = Client('https://bity.com/');
  print(await client.estimate("BTC", 1, "CHF"));
  await client.close();
}
