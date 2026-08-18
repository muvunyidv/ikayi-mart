import 'package:flutter/foundation.dart';

/// REST origin for the NestJS API (`/api/v1`).
/// Override with `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api/v1';
  }
  return 'http://localhost:3000/api/v1';
}
