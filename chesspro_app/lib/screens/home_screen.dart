import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(
        "Home Screen",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppStyles.getDefaultColor(context),
        ),
      ),
    );
  }
}
