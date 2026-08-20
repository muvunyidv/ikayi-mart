import 'package:flutter/foundation.dart';

/// Live NestJS API on Render (`/api/v1`).
const kProductionApiBaseUrl = 'https://ikayi-mart-backend.onrender.com/api/v1';

/// Socket.io origin for the Render backend (no `/api/v1` prefix).
/// The NestJS `/orders` namespace is served from this host.
const kProductionSocketOrigin = 'https://ikayi-mart-backend.onrender.com';

bool get _useProductionHost => kReleaseMode || kIsWeb;

/// REST origin for the NestJS API (`/api/v1`).
///
/// Production is used for web builds and release mode.
/// Override with `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (_useProductionHost) return kProductionApiBaseUrl;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api/v1';
  }
  return 'http://localhost:3000/api/v1';
}

/// Socket.io origin (scheme + host, no `/api/v1`).
///
/// Follows the same production/local split as [resolveApiBaseUrl].
/// Override with `--dart-define=SOCKET_ORIGIN=https://api.example.com`.
String resolveSocketOrigin() {
  const fromEnv = String.fromEnvironment('SOCKET_ORIGIN');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (_useProductionHost) return kProductionSocketOrigin;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

/// Google OAuth 2.0 **Web** client ID.
///
/// Used as `GoogleSignIn.clientId` on web and `serverClientId` on Android so
/// the ID token audience matches `GOOGLE_CLIENT_ID` on the NestJS API.
/// Override with `--dart-define=GOOGLE_CLIENT_ID=....apps.googleusercontent.com`.
String resolveGoogleClientId() {
  const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID');
  return fromEnv;
}
