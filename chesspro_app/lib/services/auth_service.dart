import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chesspro_app/utils/storage_helper.dart';

class AuthService {
  static Future<bool> checkAndRefreshToken() async {
    String? accessToken = await StorageHelper.readToken('access_token');
    String? refreshToken = await StorageHelper.readToken('refresh_token');

    if (accessToken == null || refreshToken == null) {
      return false; // No tokens, force login
    }

    bool isTokenValid = await _testAccessToken(accessToken);
    if (!isTokenValid) {
      return await refreshAccessToken(refreshToken);
    }

    return true; // Access token is valid
  }

  static Future<bool> _testAccessToken(String accessToken) async {
    final response = await http.get(
      Uri.parse('http://3.16.27.216:3264/test-access-token'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return response.statusCode != 401; // 401 means expired
  }

  static Future<bool> refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('http://3.16.27.216:3264/refresh'),
      body: jsonEncode({'refreshToken': refreshToken}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await StorageHelper.saveToken('access_token', data['accessToken']);
      return true;
    } else {
      await StorageHelper.clearTokens(); // Log user out if refresh fails
      return false;
    }
  }

  static Future getAccessToken() async {
    String? accessToken = await StorageHelper.readToken('access_token');
    if (accessToken == null) {
      return null; // No access token available
    }
    return accessToken;
  }

  static Future getRefreshToken() async {
    String? refreshToken = await StorageHelper.readToken('refresh_token');
    if (refreshToken == null) {
      return null; // No refresh token available
    }
    return refreshToken;
  }
}
