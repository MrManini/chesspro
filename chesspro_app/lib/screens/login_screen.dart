import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:chesspro_app/utils/styles.dart';
import 'package:chesspro_app/widgets/password_text_field.dart';
import 'package:chesspro_app/services/api_service.dart';
import 'package:chesspro_app/utils/storage_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameOrEmailController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  static var logger = Logger();

  Future<void> login(context) async {
    final response = await ApiService.loginUser(
      usernameOrEmailController.text, // Can be either username or email
      passwordController.text,
    );

    if (response != null && response.containsKey("tokens")) {
      logger.i("Login successful: $response");

      // Save tokens and user info
      await StorageHelper.saveToken(
        'access_token',
        response['tokens']['accessToken'],
      );
      await StorageHelper.saveToken(
        'refresh_token',
        response['tokens']['refreshToken'],
      );
      await StorageHelper.saveUserInfo(
        response['user']['username'],
        response['user']['email'],
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
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
            SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }
}
