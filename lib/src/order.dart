class Order {
  final String id;
  final PaymentDetails paymentDetails;
  final Input input;

  Order.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        paymentDetails = PaymentDetails.fromJson(json['payment_details']),
        input = Input.fromJson(json['input']);
}

class PaymentDetails {
  final String type;
  final String cryptoAddress;
  final String bankAccount;

  PaymentDetails.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        cryptoAddress = json['crypto_address'],
        bankAccount = json['bank_account'];
}

class Input {
  final double amount;

  Input.fromJson(Map<String, dynamic> json)
      : amount = double.parse(json['amount']);
}
