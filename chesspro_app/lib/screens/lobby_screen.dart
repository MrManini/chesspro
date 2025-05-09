import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:chesspro_app/services/api_service.dart';
import 'package:chesspro_app/services/auth_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  LobbyScreenState createState() => LobbyScreenState();
}

class LobbyScreenState extends State<LobbyScreen> {
  WebSocketChannel? channel;
  bool serverConnected = false;
  String selectedColor = "random";
  List<String> players = []; // will be filled with actual users
  bool gameReady = false;
  static var logger = Logger();

  @override
  void initState() {
    super.initState();
    setupWebSocket();
  }

  void setupWebSocket() async {
    String token = await AuthService.getAccessToken();
    channel = ApiService.connectToWebSocket(token);

    channel!.stream.listen(
      (data) {
        logger.i("Received: $data");
        final message = parseMessage(data);

        if (message["type"] == "player_list") {
          setState(() {
            players = List<String>.from(message["players"]);
          });
        } else if (message["type"] == "game_ready") {
          setState(() {
            gameReady = true;
          });
        }

        // If first successful message, mark as connected
        if (!serverConnected) {
          setState(() {
            serverConnected = true;
          });
        }
      },
      onDone: () {
        logger.w("WebSocket connection closed");
        setState(() => serverConnected = false);
      },
      onError: (error) {
        logger.e(error);
        setState(() => serverConnected = false);
      },
    );
  }

  void selectColor(String color) {
    setState(() {
      selectedColor = color;
    });
    if (serverConnected && channel != null) {
      ApiService.sendMessage(channel!, {
        "command": "admin.set_color",
        "color": color,
      });
    }
  }

  void startGame() {
    if (serverConnected && players.length >= 2) {
      ApiService.sendMessage(channel!, {"command": "admin.start_game"});
      Navigator.pushReplacementNamed(context, '/chess');
    }
  }

  @override
  void dispose() {
    if (channel != null) {
      ApiService.closeWebSocket(channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canStart = serverConnected && players.length >= 2;

    return Scaffold(
      appBar: AppBar(title: Text("Lobby")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Connecting to Board... (not implemented)"),
            Text(
              serverConnected
                  ? "Connected to server!"
                  : "Connecting to server...",
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  ["white", "random", "black"].map((color) {
                    return ElevatedButton(
                      onPressed: () => selectColor(color),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedColor == color ? Colors.green : null,
                      ),
                      child: Text(color.toUpperCase()),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            Text("Players:"),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder:
                    (_, index) => ListTile(title: Text(players[index])),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: canStart ? startGame : null,
              child: Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> parseMessage(dynamic data) {
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      LobbyScreenState.logger.e("Error parsing message: $e");
      return {}; // return empty map if it fails
    }
  }
}
