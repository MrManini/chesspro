import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chesspro_app/utils/styles.dart';
import 'package:chesspro_app/widgets/password_text_field.dart';
import 'package:chesspro_app/services/api_service.dart';


class LoginScreen extends StatelessWidget {
  final TextEditingController usernameOrEmailController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  static var logger = Logger();
  final storage = FlutterSecureStorage();

  LoginScreen({super.key});

  void login(context) async {
    final response = await ApiService.loginUser(
      usernameOrEmailController.text, // Can be either username or email
      passwordController.text,
    );

    if (response != null && response.containsKey("tokens")) {
      logger.i("Login successful: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      logger.e("Login failed");
      String errorMessage = response?["error"] ?? "Unknown error";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed 😢\n$errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 25,
                  color: AppStyles.getDefaultColor(context),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  );
                },
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Ready to Play?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.getDefaultColor(context),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: usernameOrEmailController,
                      decoration: AppStyles.getTextFieldStyle(context).copyWith(
                        hintText: "Username or Email",
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppStyles.getDefaultColor(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    PasswordTextField(
                      controller: passwordController,
                      decoration: AppStyles.getTextFieldStyle(context),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        login(context);
                      },
                      style: AppStyles.getPrimaryButtonStyle(context),
                      child: Text("Log In", style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the login screen
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: AppStyles.getDefaultColor(context),
                          ),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
