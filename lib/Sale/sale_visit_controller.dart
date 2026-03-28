
import 'models/customer_visit_model.dart';
import 'models/sale_order_model.dart';

class SaleVisitController {
  CustomerVisit? selectedCustomer;
  List<SaleItem> selectedItems = [];

  /// Select the customer
  void selectCustomer(CustomerVisit customer) {
    selectedCustomer = customer;
  }

  /// Add item to the selected list
  void addItem(SaleItem item) {
    selectedItems.add(item);
  }

  /// Remove item from the selected list
  void removeItem(SaleItem item) {
    selectedItems.remove(item);
  }

  /// Clear all selected items
  void clearItems() {
    selectedItems.clear();
  }
}