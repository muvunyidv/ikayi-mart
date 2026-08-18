import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/ikayi_api.dart';
import '../core/models/models.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._api);

  static const _tokenKey = 'ikayi_jwt';

  final IkayiApi _api;

  VendorUser? user;
  bool restoring = true;
  String? error;

  bool get isLoggedIn => user != null && (_api.client.token?.isNotEmpty ?? false);

  Future<void> restore() async {
    restoring = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        restoring = false;
        notifyListeners();
        return;
      }
      _api.setToken(token);
      user = await _api.me();
    } catch (_) {
      _api.setToken(null);
      user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _authenticate(
      () => _api.login(email: email, password: password),
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String storeName,
  }) async {
    return _authenticate(
      () => _api.registerVendor(
        email: email,
        password: password,
        name: name,
        storeName: storeName,
      ),
    );
  }

  Future<bool> _authenticate(
    Future<({VendorUser user, String accessToken})> Function() request,
  ) async {
    error = null;
    notifyListeners();
    try {
      final result = await request();
      _api.setToken(result.accessToken);
      user = result.user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.accessToken);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _api.setToken(null);
    user = null;
    error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
