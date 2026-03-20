class Customer {
  String code;
  String name;
  String phone;
  String address;

  Customer({
    required this.code,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class SaleItem {
  String itemCode;
  String name;
  int qty;
  double price;
  String uom;

  SaleItem({
    required this.itemCode,
    required this.name,
    this.qty = 1,
    required this.price,
    this.uom = "PCS",
  });
}