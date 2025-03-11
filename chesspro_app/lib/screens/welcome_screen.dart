import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'login_screen.dart';
//import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;
    Color whiteButtonColor = Color(0xffced4da);
    Color blackButtonColor = Color(0xff343a40);

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
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? blackButtonColor : whiteButtonColor,
                    foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text("Login", style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: screenWidth * 0.9,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? whiteButtonColor : blackButtonColor,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
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
