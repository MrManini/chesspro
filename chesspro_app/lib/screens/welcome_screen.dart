import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo-light.svg', // Path to your SVG file
              width: 300, // Adjust size as needed
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                //Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: Text("Login"),
            ),
            ElevatedButton(
              onPressed: () {
                //Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
              },
              child: Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
