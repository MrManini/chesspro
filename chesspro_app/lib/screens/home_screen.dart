import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chesspro_app/utils/storage_helper.dart';
import 'package:chesspro_app/utils/styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? username;
  bool showButtons = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void toggleButtons() {
    setState(() {
      showButtons = !showButtons;
      if (showButtons) {
        _controller.forward(); // Expand
      } else {
        _controller.reverse(); // Collapse
      }
    });
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
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.settings),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _logout(context);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Text('Logout'),
                              ),
                            ],
                      ),
                    ),
                    SvgPicture.asset(
                      isDarkMode
                          ? 'assets/logo-dark.svg'
                          : 'assets/logo-light.svg',
                      width: screenWidth * 0.6,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: toggleButtons,
                      style: AppStyles.getPrimaryButtonStyle(context),
                      child: Text(
                        "Create Game",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizeTransition(
                      sizeFactor: _animation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/lobby',
                                    );
                                  },
                                  style: AppStyles.getSecondaryButtonStyle(
                                    context,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/mode-pvp.svg',
                                        width: 100,
                                        colorFilter: null,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Player vs Player'),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/chess',
                                    );
                                  },
                                  style: AppStyles.getSecondaryButtonStyle(
                                    context,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/mode-pvb.svg',
                                        width: 100,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Player vs Bot'),
                                    ],
                                  ),
                                ),
                              ),
/*                               SizedBox(
                                width: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/chess',
                                    );
                                  },
                                  style: AppStyles.getSecondaryButtonStyle(
                                    context,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/mode-bvb.svg',
                                        width: 100,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Bot vs Bot'),
                                    ],
                                  ),
                                ),
                              ), */
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: AppStyles.getSecondaryButtonStyle(context),
                      child: Text("Join Game", style: TextStyle(fontSize: 20)),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
