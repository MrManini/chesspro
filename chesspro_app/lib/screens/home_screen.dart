import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/storage_helper.dart';
import 'package:chesspro_app/utils/styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    String? user = await StorageHelper.getUserUsername();
    setState(() {
      username = user;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await StorageHelper.clearTokens();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/welcome');
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
          Text(
            username != null ? "Welcome, $username!" : "Loading...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppStyles.getDefaultColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
