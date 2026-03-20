import 'models/sale_order_model.dart';

class SaleController {
  Customer? selectedCustomer;
  List<SaleItem> selectedItems = [];

  void selectCustomer(Customer customer) {
    selectedCustomer = customer;
    selectedItems.clear();
  }

  void addItem(SaleItem item) {
    selectedItems.add(item);
  }

  void removeItem(SaleItem item) {
    selectedItems.remove(item);
  }

  void updateItemQty(SaleItem item, int qty) {
    int index = selectedItems.indexOf(item);
    if (index != -1) {
      selectedItems[index].qty = qty;
    }
  }

  double get subtotal {
    return selectedItems.fold(
        0, (previousValue, element) => previousValue + element.price * element.qty);
  }

  double runPromotion() {
    // Mock promotion: 10% off if subtotal > 50
    double sub = subtotal;
    if (sub > 50) return sub * 0.9;
    return sub;
  }
}