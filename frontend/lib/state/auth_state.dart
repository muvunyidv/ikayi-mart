import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_config.dart';
import '../core/api/ikayi_api.dart';
import '../core/models/models.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._api)
      : _googleSignIn = GoogleSignIn(
          // On web, extra scopes make `signIn()` call People API. GIS already
          // grants openid/email/profile. Keep scopes for mobile sign-in.
          scopes: kIsWeb ? const <String>[] : const ['email', 'profile'],
          clientId: kIsWeb && resolveGoogleClientId().isNotEmpty
              ? resolveGoogleClientId()
              : null,
          serverClientId: resolveGoogleClientId().isEmpty
              ? null
              : resolveGoogleClientId(),
        ) {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _latestGoogleAccount = account;
    });
  }

  static const _tokenKey = 'ikayi_jwt';
  static const _avatarKey = 'ikayi_avatar_url';
  static const _avatarUserKey = 'ikayi_avatar_user';

  final IkayiApi _api;
  final GoogleSignIn _googleSignIn;

  VendorUser? user;
  String? avatarUrl;
  bool restoring = true;
  String? error;
  Future<bool>? _googleInFlight;
  GoogleSignInAccount? _latestGoogleAccount;

  bool get isLoggedIn => user != null && (_api.client.token?.isNotEmpty ?? false);

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// GIS web button notifies here after the user picks a Google account.
  Stream<GoogleSignInAccount?> get googleAccountChanges =>
      _googleSignIn.onCurrentUserChanged;

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
      await _restoreAvatar(prefs, user?.id);
    } catch (_) {
      _api.setToken(null);
      user = null;
      avatarUrl = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_avatarKey);
      await prefs.remove(_avatarUserKey);
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

  Future<bool> loginWithGoogle({String? orderId}) {
    return _googleInFlight ??= _loginWithGoogle(orderId: orderId).whenComplete(() {
      _googleInFlight = null;
    });
  }

  Future<bool> _loginWithGoogle({String? orderId}) async {
    error = null;
    notifyListeners();
    try {
      if (isLoggedIn && orderId == null) {
        return true;
      }

      final clientId = resolveGoogleClientId();
      if (clientId.isEmpty) {
        error =
            'Google Sign-In is not configured. Pass --dart-define=GOOGLE_CLIENT_ID=...';
        notifyListeners();
        return false;
      }

      GoogleSignInAccount? account =
          _latestGoogleAccount ?? _googleSignIn.currentUser;
      if (account == null && !kIsWeb) {
        account = await _googleSignIn.signIn();
      }
      if (account == null) {
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        error = 'Google did not return an ID token. Check the Web client ID.';
        await _clearGoogleSession();
        notifyListeners();
        return false;
      }

      final photoUrl = _nonEmpty(account.photoUrl) ?? _pictureFromIdToken(idToken);
      final ok = await _authenticate(
        () => _api.loginWithGoogle(idToken: idToken, orderId: orderId),
        avatarUrl: photoUrl,
      );
      if (!ok) {
        await _clearGoogleSession();
      }
      return ok;
    } catch (e) {
      error = _friendlyGoogleError(e);
      await _clearGoogleSession();
      notifyListeners();
      return false;
    }
  }

  Future<void> _clearGoogleSession() async {
    _latestGoogleAccount = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  String _friendlyGoogleError(Object e) {
    final raw = e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('people api') ||
        lower.contains('people.googleapis.com') ||
        lower.contains('service_disabled')) {
      return 'Google Sign-In is missing a required API on the server. Try again, or use email and password.';
    }
    if (raw.length > 180) {
      return 'Google Sign-In failed. Please try again.';
    }
    return raw;
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
    Future<({VendorUser user, String accessToken})> Function() request, {
    String? avatarUrl,
  }) async {
    error = null;
    notifyListeners();
    try {
      final result = await request();
      _api.setToken(result.accessToken);
      user = result.user;
      this.avatarUrl = _nonEmpty(avatarUrl);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result.accessToken);
      await _persistAvatar(prefs, result.user.id, this.avatarUrl);
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
    avatarUrl = null;
    error = null;
    _latestGoogleAccount = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_avatarKey);
    await prefs.remove(_avatarUserKey);
    notifyListeners();
  }

  Future<void> _restoreAvatar(SharedPreferences prefs, String? userId) async {
    final savedUser = prefs.getString(_avatarUserKey);
    final savedUrl = prefs.getString(_avatarKey);
    if (userId != null && savedUser == userId && _nonEmpty(savedUrl) != null) {
      avatarUrl = savedUrl;
    } else {
      avatarUrl = null;
      await prefs.remove(_avatarKey);
      await prefs.remove(_avatarUserKey);
    }
  }

  Future<void> _persistAvatar(
    SharedPreferences prefs,
    String userId,
    String? url,
  ) async {
    final photo = _nonEmpty(url);
    if (photo == null) {
      await prefs.remove(_avatarKey);
      await prefs.remove(_avatarUserKey);
      return;
    }
    await prefs.setString(_avatarKey, photo);
    await prefs.setString(_avatarUserKey, userId);
  }

  String? _pictureFromIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return _nonEmpty(map['picture'] as String?);
    } catch (_) {
      return null;
    }
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
