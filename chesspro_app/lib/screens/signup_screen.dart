import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:chesspro_app/utils/styles.dart';
import 'package:chesspro_app/widgets/password_text_field.dart';
import 'package:chesspro_app/services/api_service.dart';
import 'package:chesspro_app/utils/storage_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  final ValueNotifier<bool> isPasswordVisibleNotifier = ValueNotifier(false);
  static var logger = Logger();

  void signUp(context) async {
    if (passwordController.text != passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❕ Passwords don't match."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await ApiService.signUpUser(
      usernameController.text,
      emailController.text,
      passwordController.text,
    );

    if (response != null && !response.containsKey("error")) {
      logger.i("Sign-up successful: $response");

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
          content: Text('User created successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      logger.e("Sign-up failed");
      String errorMessage = "";
      if (response != null && response.containsKey("error")) {
        errorMessage = response["error"];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user 😢\n$errorMessage'),
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
                      isPasswordVisibleNotifier: isPasswordVisibleNotifier,
                    ),
                    SizedBox(height: 10),
                    ConfirmPasswordField(
                      controller: passwordConfirmController,
                      decoration: AppStyles.getTextFieldStyle(context),
                      isPasswordVisibleNotifier: isPasswordVisibleNotifier,
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
          ],
        ),
      ),
    );
  }
}
