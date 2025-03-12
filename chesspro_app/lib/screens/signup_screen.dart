import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/styles.dart';
import 'package:chesspro_app/widgets/password_text_field.dart';
import 'package:chesspro_app/services/api_service.dart';
import 'package:logger/logger.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  static var logger = Logger();

  SignupScreen({super.key});

  void signUp(context) async {
    final response = await ApiService.signUpUser(
      usernameController.text,
      emailController.text,
      passwordController.text,
    );

    if (response != null) {
      logger.i("Sign-up successful: $response");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });

    } else {
      logger.e("Sign-up failed");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user 😢'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      "Create an Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.getDefaultColor(context),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: AppStyles.getTextFieldStyle(context).copyWith(
                        hintText: "Username",
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppStyles.getDefaultColor(context),
                        ),
                      ),
                      cursorColor: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: AppStyles.getTextFieldStyle(context).copyWith(
                        hintText: "Email",
                        prefixIcon: Icon(
                          Icons.email,
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
                        signUp(context);
                      },
                      style: AppStyles.getPrimaryButtonStyle(context),
                      child: Text("Sign Up", style: TextStyle(fontSize: 18)),
                    ),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the login screen
                        Navigator.pushNamed(context, '/login');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            color: AppStyles.getDefaultColor(context),
                          ),
                          children: [
                            TextSpan(
                              text: "Log in",
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
