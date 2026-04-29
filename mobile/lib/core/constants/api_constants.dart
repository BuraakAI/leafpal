import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _productionUrl = 'https://leafpal-386649840420.europe-west1.run.app';

  static String get baseUrl {
    // Release build → production Cloud Run
    if (!kDebugMode) return _productionUrl;
    // Debug web → localhost
    if (kIsWeb) return 'http://localhost:3000';
    // Debug Android emulator → 10.0.2.2
    return 'http://10.0.2.2:3000';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
