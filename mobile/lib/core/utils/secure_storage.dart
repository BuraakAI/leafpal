import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token storage — uses SharedPreferences on all platforms for reliability.
/// EncryptedSharedPreferences can corrupt after app data clear on Android.
class AppStorage {
  static AppStorage? _instance;
  static AppStorage get instance => _instance ??= AppStorage._();
  AppStorage._();

  SharedPreferences? _prefs;

  // Keep secure storage only for non-web builds that explicitly need it.
  FlutterSecureStorage? _secure;

  FlutterSecureStorage get _secureStorage {
    _secure ??= const FlutterSecureStorage(
      webOptions: WebOptions(dbName: 'leafpal', publicKey: 'leafpal-key'),
      // encryptedSharedPreferences disabled — causes KeyStore corruption after
      // app data clear on Android, making token unreadable after re-login.
      aOptions: AndroidOptions(encryptedSharedPreferences: false),
    );
    return _secure!;
  }

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } else {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (_) {
        // Fallback to SharedPreferences if secure storage fails
        final prefs = await _getPrefs();
        await prefs.setString('sp_$key', value);
      }
    }
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } else {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null) return val;
        // Also check SharedPreferences fallback
        final prefs = await _getPrefs();
        return prefs.getString('sp_$key');
      } catch (_) {
        final prefs = await _getPrefs();
        return prefs.getString('sp_$key');
      }
    }
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } else {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
      final prefs = await _getPrefs();
      await prefs.remove('sp_$key');
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
