import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readToken(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
