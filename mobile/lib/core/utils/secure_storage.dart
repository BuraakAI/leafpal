import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Web'de flutter_secure_storage localStorage kullanır ama
// web options ayarlanmazsa hata verir. Bu wrapper her platformda çalışır.
class AppStorage {
  static AppStorage? _instance;
  static AppStorage get instance => _instance ??= AppStorage._();
  AppStorage._();

  FlutterSecureStorage? _secure;
  SharedPreferences? _prefs;

  FlutterSecureStorage get _secureStorage {
    _secure ??= const FlutterSecureStorage(
      webOptions: WebOptions(dbName: 'leafpal', publicKey: 'leafpal-key'),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return _secure!;
  }

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } else {
      return _secureStorage.read(key: key);
    }
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
