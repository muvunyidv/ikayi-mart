import 'package:flutter/foundation.dart';

enum AppMode { shopper, vendor }

enum VendorSection { dashboard, inventory, orders, bmsSync, support }

/// Toggles consumer storefront vs vendor dashboard, plus vendor section.
class NavigationState extends ChangeNotifier {
  AppMode _mode = AppMode.shopper;
  VendorSection _vendorSection = VendorSection.dashboard;
  String _selectedCategory = 'All';
  String _selectedDistrict = 'Nyarugenge';
  String _selectedSector = 'Nyarugenge';

  AppMode get mode => _mode;
  VendorSection get vendorSection => _vendorSection;
  String get selectedCategory => _selectedCategory;
  String get selectedDistrict => _selectedDistrict;
  String get selectedSector => _selectedSector;

  String get locationLabel => '$_selectedSector, $_selectedDistrict';

  void setMode(AppMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggleMode() {
    setMode(_mode == AppMode.shopper ? AppMode.vendor : AppMode.shopper);
  }

  void setVendorSection(VendorSection section) {
    if (_vendorSection == section) return;
    _vendorSection = section;
    if (_mode != AppMode.vendor) {
      _mode = AppMode.vendor;
    }
    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setLocation({required String district, required String sector}) {
    _selectedDistrict = district;
    _selectedSector = sector;
    notifyListeners();
  }
}
