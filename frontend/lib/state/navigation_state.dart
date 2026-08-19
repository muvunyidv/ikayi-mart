import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { shopper, vendor }

enum VendorSection { dashboard, inventory, orders, bmsSync, support }

/// Toggles consumer storefront vs vendor dashboard, plus vendor section.
class NavigationState extends ChangeNotifier {
  NavigationState() {
    _restoreSidebarPrefs();
  }

  static const _vendorSidebarKey = 'sidebar_vendor_collapsed';

  AppMode _mode = AppMode.shopper;
  VendorSection _vendorSection = VendorSection.dashboard;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedDistrict = 'Nyarugenge';
  String _selectedSector = 'Nyarugenge';
  bool _shopperSidebarCollapsed = true;
  bool _vendorSidebarCollapsed = false;

  AppMode get mode => _mode;
  VendorSection get vendorSection => _vendorSection;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get selectedDistrict => _selectedDistrict;
  String get selectedSector => _selectedSector;
  bool get shopperSidebarCollapsed => _shopperSidebarCollapsed;
  bool get vendorSidebarCollapsed => _vendorSidebarCollapsed;

  String get locationLabel => '$_selectedSector, $_selectedDistrict';

  Future<void> _restoreSidebarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final vendor = prefs.getBool(_vendorSidebarKey);
    if (vendor == null) return;
    _vendorSidebarCollapsed = vendor;
    notifyListeners();
  }

  Future<void> _persistSidebarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vendorSidebarKey, _vendorSidebarCollapsed);
  }

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

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setLocation({required String district, required String sector}) {
    _selectedDistrict = district;
    _selectedSector = sector;
    notifyListeners();
  }

  void toggleShopperSidebar() {
    _shopperSidebarCollapsed = !_shopperSidebarCollapsed;
    notifyListeners();
  }

  void toggleVendorSidebar() {
    _vendorSidebarCollapsed = !_vendorSidebarCollapsed;
    notifyListeners();
    _persistSidebarPrefs();
  }
}
