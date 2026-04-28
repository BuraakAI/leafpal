import 'package:flutter/foundation.dart';

class ApiConstants {
  // Web → localhost, Android emülatör → 10.0.2.2, fiziksel cihaz → LAN IP girin
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
