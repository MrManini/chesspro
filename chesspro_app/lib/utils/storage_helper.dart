import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveUserInfo(String username, String email) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'email', value: email);
  }

  static Future<String?> getUserUsername() async {
    return await _storage.read(key: 'username');
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: 'email');
  }

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
