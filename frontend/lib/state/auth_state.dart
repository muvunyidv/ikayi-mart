import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_config.dart';
import '../core/api/ikayi_api.dart';
import '../core/models/models.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._api)
      : _googleSignIn = GoogleSignIn(
          scopes: const ['email', 'profile'],
          clientId: kIsWeb && resolveGoogleClientId().isNotEmpty
              ? resolveGoogleClientId()
              : null,
          serverClientId: resolveGoogleClientId().isEmpty
              ? null
              : resolveGoogleClientId(),
        );

  static const _tokenKey = 'ikayi_jwt';

  final IkayiApi _api;
  final GoogleSignIn _googleSignIn;

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

  Future<bool> loginWithGoogle({String? orderId}) async {
    error = null;
    notifyListeners();
    try {
      final clientId = resolveGoogleClientId();
      if (clientId.isEmpty) {
        error =
            'Google Sign-In is not configured. Pass --dart-define=GOOGLE_CLIENT_ID=...';
        notifyListeners();
        return false;
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        error = 'Google did not return an ID token. Check the Web client ID.';
        notifyListeners();
        return false;
      }

      return _authenticate(
        () => _api.loginWithGoogle(idToken: idToken, orderId: orderId),
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> convertGuest({
    required String orderId,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => _api.convertGuest(
        orderId: orderId,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> claimGuestOrder(String orderId) async {
    await _api.claimGuestOrder(orderId);
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
