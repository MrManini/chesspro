import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chesspro_app/utils/styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SvgPicture.asset(
                isDarkMode ? 'assets/logo-dark.svg' : 'assets/logo-light.svg',
                width: screenWidth * 0.9,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: AppStyles.getSecondaryButtonStyle(context),
                  child: Text("Login", style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: AppStyles.getPrimaryButtonStyle(context),
                  child: Text("Sign Up", style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
