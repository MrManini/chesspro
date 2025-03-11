import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/styles.dart';
import 'package:chesspro_app/widgets/password_text_field.dart';

class LoginScreen extends StatelessWidget {

  final TextEditingController usernameOrEmailController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

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
                icon: Icon(Icons.arrow_back, size: 25, color: AppStyles.getDefaultColor(context)),
                onPressed: () {Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);},
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
                        // TODO: Handle login logic
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
                          style: TextStyle(color: AppStyles.getDefaultColor(context)),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
