/// This class is required when placing orders.
class Owner {
  Owner(
    this.address,
    this.city,
    this.zip,
    this.country,
    this.name,
  );

  /// Should have been called 'street' but 'address' mirrors the API
  final String address;

  /// Should have been called 'countryCode' but 'country' mirrors the API
  final String country;

  final String city;
  final String zip;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'country': country,
      'city': city,
      'zip': zip,
      'name': name,
    };
  }
}
