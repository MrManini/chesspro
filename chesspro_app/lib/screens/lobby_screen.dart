import 'dart:async';
import 'dart:convert';
import 'package:chesspro_app/screens/chess_screen.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:chesspro_app/services/api_service.dart';
import 'package:chesspro_app/services/auth_service.dart';

class LobbyScreen extends StatefulWidget {
  final bool isAdmin;
  final String? gamemode;
  const LobbyScreen({super.key, this.isAdmin = false, this.gamemode});

  @override
  LobbyScreenState createState() => LobbyScreenState();
}

class LobbyScreenState extends State<LobbyScreen> {
  WebSocketChannel? channel;
  bool serverConnected = false;
  String? selectedColor;
  List<String> players = []; // will be filled with actual users
  bool gameReady = false;
  static var logger = Logger();
  late StreamSubscription channelSubscription;
  late Stream<dynamic> broadcastStream;
  String role = "spectator"; // Default role

  @override
  void initState() {
    super.initState();
    setupWebSocket();
  }

  void setupWebSocket() async {
    String token = await AuthService.getAccessToken();
    channel = ApiService.connectToWebSocket(token, isAdmin: widget.isAdmin);
    if (widget.isAdmin) {
      ApiService.sendMessage(channel!, {
        "command": "admin.set_mode",
        "mode": widget.gamemode,
      });
      logger.i("Admin mode set to: ${widget.gamemode}");
    }
    broadcastStream = channel!.stream.asBroadcastStream();

    broadcastStream.listen(
      (data) {
        logger.i("Received: $data");
        final message = parseMessage(data);

        if (message["type"] == "player_list") {
          setState(() {
            players = List<String>.from(message["clients"]);
          });
        } else if (message["type"] == "user_connected") {
          // Option 1: If the message contains the full player list
          if (message.containsKey("players")) {
            setState(() {
              players = List<String>.from(message["clients"]);
            });
          }
          // Option 2: If the message only contains the new user's name
          else if (message.containsKey("username")) {
            setState(() {
              if (!players.contains(message["username"])) {
                players.add(message["username"]);
              }
            });
          }
        } else if (message["type"] == "role") {
          setState(() {
            role = message["role"];
          });
        } else if (message["type"] == "color_set" && role == "player2") {
          setState(() {
            selectedColor = message["color"] == "white" ? "black" : "white";
          });
        } else if (message["type"] == "game_ready") {
          setState(() {
            gameReady = true;
          });
        } else if (message["type"] == "user_disconnected") {
          if (message.containsKey("username")) {
            setState(() {
              players.remove(message["username"]);
            });
          }
        } else if (message["type"] == "game_started") {
          if (!widget.isAdmin) {
            if (!mounted) return; // <-- Add this line
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChessScreen(
                  color: selectedColor,
                  channel: channel,
                  stream: broadcastStream,
                ),
              ),
            );
          }
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
    if (!widget.isAdmin) return;
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
    if (!widget.isAdmin) return;
    if (serverConnected && players.length >= 2) {
      try {
        if (selectedColor == null) {
            selectedColor = (["white", "black"]..shuffle()).first;
            ApiService.sendMessage(channel!, {
              "command": "admin.set_color",
              "color": selectedColor,
            });
        }
        ApiService.sendMessage(channel!, {"command": "admin.start_game"});
        logger.i("Starting game with color: $selectedColor");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChessScreen(
                  color: selectedColor,
                  channel: channel,
                  stream: broadcastStream,
                ),
          ),
        );
      } catch (e) {
        logger.e("Error starting game: $e");
      }
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
            Text(
              serverConnected
                  ? "Connected to server!"
                  : "Connecting to server...",
            ),
            SizedBox(height: 20),
            if (widget.isAdmin) ...[
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
            ],
            Text("Players:"),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder:
                    (_, index) => ListTile(title: Text(players[index])),
              ),
            ),
            SizedBox(height: 10),
            if (widget.isAdmin)
              ElevatedButton(
                onPressed: canStart ? startGame : null,
                child: Text("Start Game"),
              )
            else
              Text("Waiting for admin to start the game..."),
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
