import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/storage_helper.dart';
import 'package:chesspro_app/utils/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await StorageHelper.clearTokens();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/w');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(
            "Home Screen",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.getDefaultColor(context),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ]
      )
    );
  }
}
