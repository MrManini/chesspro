import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  static const String baseUrl = "http://3.16.27.216:3264";
  static var logger = Logger();

  static Future<Map<String, dynamic>?> signUpUser(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/signup");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        logger.e("Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("Error: $e");
      return null;
    }
  }
}
