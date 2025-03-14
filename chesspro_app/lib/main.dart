import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:chesspro_app/services/auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? _initialScreen;
  static var logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    bool isLoggedIn = await AuthService.checkAndRefreshToken();
    setState(() {
      _initialScreen = isLoggedIn ? '/home' : '/welcome';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget initialScreenWidget;
    if (_initialScreen == null) {
      initialScreenWidget = Container(); // Show a blank screen while checking
    } else if (_initialScreen == '/home') {
      initialScreenWidget = HomeScreen();
    } else {
      initialScreenWidget = WelcomeScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChessPro',
      themeMode: ThemeMode.system,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: initialScreenWidget,
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
