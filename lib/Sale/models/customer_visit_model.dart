class CustomerVisit {
  final String cardCode;
  final String cardName;
  final String? phone;
  final String? fullAddress;

  CustomerVisit({
    required this.cardCode,
    required this.cardName,
    this.phone,
    this.fullAddress,
  });
}