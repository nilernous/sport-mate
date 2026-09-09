import 'package:flutter/foundation.dart';

/// Environment configuration.
///
/// Override the API origin at build time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5005`
class AppConfig {
  AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Scheme + host + port of the backend, without the `/api/v1` path.
  static String get apiOrigin {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:5005';
    // The Android emulator reaches the development machine through 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5005';
    return 'http://localhost:5005';
  }

  static String get apiBaseUrl => '$apiOrigin/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int defaultPageSize = 20;
}
