class Order {
  final String id;
  final PaymentDetails paymentDetails;
  final Input input;
  final Output output;

  Order.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        paymentDetails = PaymentDetails.fromJson(json['payment_details']),
        input = Input.fromJson(json['input']),
        output = Output.fromJson(json['output']);

  String toString() {
    return "Order: id=$id, input=$input, output=$output, paymentDetails=$paymentDetails";
  }
}

class PaymentDetails {
  final String type;
  final String cryptoAddress;
  final String bankAccount;

  PaymentDetails.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        cryptoAddress = json['crypto_address'],
        bankAccount = json['bank_account'];

  String toString() {
    return "PaymentDetails: type=$type, cryptoAddress=$cryptoAddress, bankAccount=$bankAccount";
  }
}

class Input {
  final double amount;

  Input.fromJson(Map<String, dynamic> json)
      : amount = double.parse(json['amount']);

  String toString() {
    return "Input: amount=$amount";
  }
}

class Output {
  final double amount;
  final String iban;

  Output.fromJson(Map<String, dynamic> json)
      : amount = double.parse(json['amount']),
        iban = json['iban'];

  String toString() {
    return "Output: amount=$amount, iban=$iban";
  }
}
