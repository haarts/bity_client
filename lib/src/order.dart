class Order {
  Order.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        paymentDetails = PaymentDetails.fromJson(json['payment_details']),
        priceGuaranteed = DateTime.parse(json['timestamp_price_guaranteed']),
        input = Input.fromJson(json['input']),
        output = Output.fromJson(json['output']);

  final String id;
  final PaymentDetails paymentDetails;
  final DateTime priceGuaranteed;
  final Input input;
  final Output output;

  @override
  String toString() {
    return 'Order: id=$id, input=$input, output=$output, paymentDetails=$paymentDetails, priceGuaranteed=$priceGuaranteed';
  }
}

class PaymentDetails {
  PaymentDetails.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        cryptoAddress = json['crypto_address'],
        bankAccount = json['bank_account'];

  final String type;
  final String cryptoAddress;
  final String bankAccount;

  @override
  String toString() {
    return 'PaymentDetails: type=$type, cryptoAddress=$cryptoAddress, bankAccount=$bankAccount';
  }
}

class Input {
  Input.fromJson(Map<String, dynamic> json)
      : amount = double.parse(json['amount']);

  final double amount;

  @override
  String toString() {
    return 'Input: amount=$amount';
  }
}

class Output {
  Output.fromJson(Map<String, dynamic> json)
      : amount = double.parse(json['amount']),
        iban = json['iban'];

  final double amount;
  final String iban;

  @override
  String toString() {
    return 'Output: amount=$amount, iban=$iban';
  }
}
