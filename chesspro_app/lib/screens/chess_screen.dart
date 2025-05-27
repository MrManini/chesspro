import 'dart:async';
import 'dart:convert';
import 'package:chesspro_app/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

class ChessScreen extends StatefulWidget {
  final String? color;
  final WebSocketChannel? channel;
  final Stream? stream;
  final String? whitePlayer;
  final String? blackPlayer;
  const ChessScreen({
    super.key,
    this.channel,
    this.color,
    this.stream,
    this.whitePlayer,
    this.blackPlayer,
  });

  @override
  ChessScreenState createState() => ChessScreenState();
}

class ChessScreenState extends State<ChessScreen> {
  double boardSize = 0;
  double squareSize = 0;
  String? grabbedPiece;
  String? selectedPiece;
  bool isFlipped = false;
  chess.Chess game = chess.Chess();
  static var logger = Logger();
  bool isGameOver = false;
  int promotedPieceCount = 0;
  StreamSubscription? _streamSubscription;

  Map<String, Offset> piecePositions = {
    'white_pawn1': Offset(0, 6),
    'white_pawn2': Offset(1, 6),
    'white_pawn3': Offset(2, 6),
    'white_pawn4': Offset(3, 6),
    'white_pawn5': Offset(4, 6),
    'white_pawn6': Offset(5, 6),
    'white_pawn7': Offset(6, 6),
    'white_pawn8': Offset(7, 6),

    'black_pawn1': Offset(0, 1),
    'black_pawn2': Offset(1, 1),
    'black_pawn3': Offset(2, 1),
    'black_pawn4': Offset(3, 1),
    'black_pawn5': Offset(4, 1),
    'black_pawn6': Offset(5, 1),
    'black_pawn7': Offset(6, 1),
    'black_pawn8': Offset(7, 1),

    'white_knight1': Offset(1, 7),
    'white_knight2': Offset(6, 7),
    'black_knight1': Offset(1, 0),
    'black_knight2': Offset(6, 0),

    'white_bishop1': Offset(2, 7),
    'white_bishop2': Offset(5, 7),
    'black_bishop1': Offset(2, 0),
    'black_bishop2': Offset(5, 0),

    'white_rook1': Offset(0, 7),
    'white_rook2': Offset(7, 7),
    'black_rook1': Offset(0, 0),
    'black_rook2': Offset(7, 0),

    'white_queen': Offset(3, 7),
    'black_queen': Offset(3, 0),

    'white_king': Offset(4, 7),
    'black_king': Offset(4, 0),
  };

  @override
  void initState() {
    super.initState();

    final streamToUse =
        widget.stream ?? widget.channel?.stream.asBroadcastStream();

    if (streamToUse != null) {
      _streamSubscription = streamToUse.listen((data) {
        logger.i("Received: $data");
        final message = parseMessage(data);
        if (message["type"] == "move") {
          setState(() {
            game.move(message["move"]);
            updatePiecePosition(message["move"]);
          });
        } else if (message["type"] == "reset") {
          setState(() {
            game = chess.Chess();
          });
        }
      });
    }

    if (widget.color == "black") {
      isFlipped = true; // Flip the board for black player
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  bool get isSpectator => widget.color == null;

  bool canMove(String pieceName) {
    if (isSpectator) return false;
    if (widget.color == "white" && pieceName.contains("white")) {
      return game.turn == chess.Color.WHITE;
    }
    if (widget.color == "black" && pieceName.contains("black")) {
      return game.turn == chess.Color.BLACK;
    }
    return false;
  }

  bool onMove(String from, String to, {String? promotion}) {
    // Make the move locally
    final move = {
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    };
    if (game.move(move)) {
      setState(() {});
      // Send to server if connected
      if (widget.channel != null) {
        widget.channel!.sink.add(jsonEncode({"type": "move", "move": move}));
      }
      endGame();
      return true;
    }
    return false;
  }

  void updatePiecePosition(move) {
    // Update the piece position in the piecePositions map
    Offset from = _convertToOffset(move['from']);
    Offset to = _convertToOffset(move['to']);
    String pieceAtPosition = '';
    for (var entry in piecePositions.entries) {
      if (entry.value == from) {
        pieceAtPosition = entry.key;
        break;
      }
    }

    // Remove the piece from its old position
    piecePositions.remove(pieceAtPosition);

    // Add the piece to its new position
    piecePositions[pieceAtPosition] = to;
  }

  @override
  Widget build(BuildContext context) {
    boardSize = MediaQuery.of(context).size.width;
    squareSize = boardSize / 8;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top elements
            // Top username (blackPlayer, usually black)
            if (widget.blackPlayer != null && widget.whitePlayer != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  isFlipped ? widget.whitePlayer! : widget.blackPlayer!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            SizedBox(
              width: boardSize,
              height: boardSize,
              child: Stack(
                children: [
                  // Chessboard
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemBuilder: (context, index) {
                          int x = index % 8;
                          int y = index ~/ 8;
                          if (isFlipped) {
                            x = 7 - x;
                            y = 7 - y;
                          }
                          bool isLightSquare = (x + y) % 2 == 0;
                          return GestureDetector(
                            onTap: () => onSquareTapped(x, y),
                            child: Container(
                              color:
                                  isLightSquare
                                      ? Color(0xffEEEEE9)
                                      : Color.fromARGB(255, 43, 43, 44),
                              child:
                                  selectedPiece != null &&
                                          piecePositions[selectedPiece] ==
                                              Offset(x.toDouble(), y.toDouble())
                                      ? Container(
                                        color: Color(0x800000ff),
                                      ) // Highlight on selection
                                      : null,
                            ),
                          );
                        },
                        itemCount: 64,
                      ),
                    ),
                  ),

                  // Pieces
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemBuilder: (context, index) {
                          int x = index % 8;
                          int y = index ~/ 8;
                          if (isFlipped) {
                            x = 7 - x;
                            y = 7 - y;
                          }
                          Offset position = Offset(x.toDouble(), y.toDouble());

                          String? pieceAtPosition;
                          for (var entry in piecePositions.entries) {
                            if (entry.value == position) {
                              pieceAtPosition = entry.key;
                              break;
                            }
                          }

                          return DragTarget<String>(
                            onAcceptWithDetails: (details) {
                              onDragAccept(details, position);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return GestureDetector(
                                onTap: () {
                                  onSquareTapped(x, y);
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child:
                                      pieceAtPosition != null
                                          ? (isGameOver ||
                                                  ((game.turn ==
                                                              chess
                                                                  .Color
                                                                  .WHITE &&
                                                          !pieceAtPosition
                                                              .contains(
                                                                'white',
                                                              )) ||
                                                      (game.turn ==
                                                              chess
                                                                  .Color
                                                                  .BLACK &&
                                                          !pieceAtPosition
                                                              .contains(
                                                                'black',
                                                              )))
                                              ? SizedBox(
                                                width: squareSize,
                                                height: squareSize,
                                                child: Image.asset(
                                                  getPieceImage(
                                                    pieceAtPosition,
                                                  ),
                                                ),
                                              )
                                              : Draggable<String>(
                                                data: pieceAtPosition,
                                                feedback: SizedBox(
                                                  width: squareSize,
                                                  height: squareSize,
                                                  child: Image.asset(
                                                    getPieceImage(
                                                      pieceAtPosition,
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Container(),
                                                onDragStarted: () {
                                                  onDragStarted(
                                                    pieceAtPosition,
                                                  );
                                                },
                                                child: SizedBox(
                                                  width: squareSize,
                                                  height: squareSize,
                                                  child: Image.asset(
                                                    getPieceImage(
                                                      pieceAtPosition,
                                                    ),
                                                  ),
                                                ),
                                              ))
                                          : null,
                                ),
                              );
                            },
                          );
                        },
                        itemCount: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom elements
            // Bottom username (whitePlayer, usually white)
            if (widget.whitePlayer != null && widget.blackPlayer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isFlipped ? widget.blackPlayer! : widget.whitePlayer!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            // Flip button
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isFlipped = !isFlipped;
                });
              },
              style: AppStyles.getPrimaryButtonStyle(context),
              child: const Text('Flip Board'),
            ),
          ],
        ),
      ),
    );
  }

  void onDragStarted(pieceAtPosition) {
    if (isGameOver || !canMove(pieceAtPosition)) {
      return;
    }
    setState(() {
      selectedPiece = pieceAtPosition;
    });
  }

  void onDragAccept(details, position) {
    if (isGameOver) return; // Prevent dragging if the game is over
    if (!canMove(details.data)) {
      selectedPiece = null;
      return;
    }

    String from = _convertToChessNotation(piecePositions[details.data]!);
    String to = _convertToChessNotation(position);

    bool isPromotionMove = _isPromotionMove(from, to);
    if (isPromotionMove) {
      _showPromotionDialog(from, to);
      return;
    }

    if (onMove(from, to)) {
      // Valid move
      setState(() {
        // Remove enemy piece if present
        String? pieceAtPosition;
        for (var entry in piecePositions.entries) {
          if (entry.value == position) {
            pieceAtPosition = entry.key;
            break;
          }
        }
        if (pieceAtPosition != null) {
          piecePositions.remove(pieceAtPosition);
        }
        // Remove pawn in case of en passant
        var lastMove = game.getHistory({'verbose': true}).last;
        if (lastMove['flags'] == 'e') {
          _handleEnPassant(lastMove);
        }
        if (lastMove['flags'] == 'k' || lastMove['flags'] == 'q') {
          _handleCastling(lastMove);
        }

        // Move the selected piece
        piecePositions[details.data] = position;
        selectedPiece = null;
      });

      // Check if the game has ended
      endGame();
    } else {
      // Invalid move
      selectedPiece = null;
    }
  }

  void onSquareTapped(int x, int y) {
    if (isGameOver) return;
    setState(() {
      // Check if there's a piece at the tapped position
      String? pieceAtPosition;
      for (var entry in piecePositions.entries) {
        if (entry.value == Offset(x.toDouble(), y.toDouble())) {
          pieceAtPosition = entry.key;
          break;
        }
      }

      if (selectedPiece == null) {
        // First tap - select the piece if there is one
        if (pieceAtPosition != null) {
          if (!canMove(pieceAtPosition)) {
            return; // Exit early if it's not the player's piece
          }
          selectedPiece = pieceAtPosition;
        }
      } else {
        // Second tap - move the selected piece or select a different piece
        String from = _convertToChessNotation(piecePositions[selectedPiece!]!);
        String to = _convertToChessNotation(Offset(x.toDouble(), y.toDouble()));

        // Select a different piece
        if (pieceAtPosition != null &&
            pieceAtPosition != selectedPiece &&
            canMove(pieceAtPosition)) {
          selectedPiece = pieceAtPosition; // Select the new piece
          return;
        }

        // Move the selected piece
        bool isPromotionMove = _isPromotionMove(from, to);
        if (isPromotionMove) {
          _showPromotionDialog(from, to);
          return;
        }
        if (onMove(from, to)) {
          // Valid move
          // Remove enemy piece if present
          if (pieceAtPosition != null) {
            piecePositions.remove(pieceAtPosition);
          }
          // Remove pawn in case of en passant
          var lastMove = game.getHistory({'verbose': true}).last;
          if (lastMove['flags'] == 'e') {
            _handleEnPassant(lastMove);
          }
          if (lastMove['flags'] == 'k' || lastMove['flags'] == 'q') {
            _handleCastling(lastMove);
          }

          // Move the selected piece
          piecePositions[selectedPiece!] = Offset(x.toDouble(), y.toDouble());
          selectedPiece = null;
        } else {
          // Invalid move
          selectedPiece = null;
        }
      }

      endGame();
    });
  }

  bool _isPromotionMove(String from, String to) {
    // Check if the move is a promotion
    bool promotionMove = false;
    game.moves({'from': from, 'to': to, 'verbose': true}).forEach((move) {
      if (move['flags'].contains('p')) {
        promotionMove = true;
      }
    });
    return promotionMove;
  }

  void _showPromotionDialog(String from, String to) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Promote Pawn"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['q', 'r', 'b', 'n'].map((piece) {
                  return IconButton(
                    icon: Image.asset(
                      getPromotionPieceImage(piece, game.turn),
                      width: 40,
                      height: 40,
                    ),
                    onPressed: () {
                      // Remove enemy piece if present
                      String? pieceAtPosition;
                      for (var entry in piecePositions.entries) {
                        if (entry.value == _convertToOffset(to)) {
                          pieceAtPosition = entry.key;
                          break;
                        }
                      }
                      if (pieceAtPosition != null) {
                        piecePositions.remove(pieceAtPosition);
                      }

                      // Perform the promotion move
                      onMove(from, to, promotion: piece);

                      setState(() {
                        // Update the promoted pawn's name in the piecePositions map
                        String promotedPieceName =
                            '${game.turn == chess.Color.WHITE ? 'black' : 'white'}_${_getPieceName(piece)}_promoted${promotedPieceCount++}';
                        piecePositions.remove(selectedPiece); // Remove the pawn
                        piecePositions[promotedPieceName] = _convertToOffset(
                          to,
                        ); // Add the promoted piece
                        selectedPiece = null;
                      });

                      Navigator.pop(context);
                      endGame();
                    },
                  );
                }).toList(),
          ),
        );
      },
    ).then((_) {
      // Reset selected piece after dialog is closed
      setState(() {
        selectedPiece = null;
      });
    });
  }

  void _handleEnPassant(lastMove) {
    String enPassantPosition = lastMove['to'];
    String file = enPassantPosition[0];
    int rank = int.parse(enPassantPosition[1]);
    String pawnKilledPosition = rank == 6 ? '${file}5' : '${file}4';
    Offset enPassantOffset = _convertToOffset(pawnKilledPosition);

    // Find the piece at the en passant position and remove it
    String? capturedPawn;
    for (var entry in piecePositions.entries) {
      if (entry.value == enPassantOffset) {
        capturedPawn = entry.key;
        break;
      }
    }
    if (capturedPawn != null) {
      piecePositions.remove(capturedPawn);
    }
  }

  void _handleCastling(lastMove) {
    if (lastMove['flags'] == 'k') {
      // Handle kingside castling
      String rookName =
          '${game.turn == chess.Color.WHITE ? 'black' : 'white'}_rook2';
      String rookTo = 'f${lastMove['to'][1]}';
      piecePositions[rookName] = _convertToOffset(rookTo);
    } else if (lastMove['flags'] == 'q') {
      // Handle queenside castling
      String rookName =
          '${game.turn == chess.Color.WHITE ? 'black' : 'white'}_rook1';
      String rookTo = 'd${lastMove['to'][1]}';
      piecePositions[rookName] = _convertToOffset(rookTo);
    }
  }

  void endGame() {
    // Check if the game has ended
    if (game.in_checkmate) {
      _showGameEndDialog(
        'Checkmate! ${game.turn == chess.Color.WHITE ? 'Black' : 'White'} wins!',
      );
    } else if (game.in_stalemate) {
      _showGameEndDialog('Stalemate! The game is a draw.');
    } else if (game.in_draw) {
      _showGameEndDialog('Draw! The game has ended in a draw.');
    } else if (game.in_threefold_repetition) {
      _showGameEndDialog('Draw! Threefold repetition occurred.');
    }
  }

  void _showGameEndDialog(String message) {
    isGameOver = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String getPieceImage(String pieceName) {
    if (pieceName.contains('pawn')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wp.png'
          : 'assets/pieces/bp.png';
    } else if (pieceName.contains('knight')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wn.png'
          : 'assets/pieces/bn.png';
    } else if (pieceName.contains('bishop')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wb.png'
          : 'assets/pieces/bb.png';
    } else if (pieceName.contains('rook')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wr.png'
          : 'assets/pieces/br.png';
    } else if (pieceName.contains('queen')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wq.png'
          : 'assets/pieces/bq.png';
    } else if (pieceName.contains('king')) {
      return pieceName.contains('white')
          ? 'assets/pieces/wk.png'
          : 'assets/pieces/bk.png';
    }
    return 'assets/pieces/wp.png'; // Fallback image
  }

  String _getPieceName(String pieceCode) {
    switch (pieceCode) {
      case 'q':
        return 'queen';
      case 'r':
        return 'rook';
      case 'b':
        return 'bishop';
      case 'n':
        return 'knight';
      default:
        return 'pawn'; // Fallback (shouldn't happen in promotion)
    }
  }

  String _convertToChessNotation(Offset position) {
    // Convert board coordinates to chess notation (e.g., (0, 6) -> "a2")
    String file = String.fromCharCode(97 + position.dx.toInt());
    String rank = (8 - position.dy.toInt()).toString();
    return '$file$rank';
  }

  Offset _convertToOffset(String notation) {
    int file = notation.codeUnitAt(0) - 97;
    int rank = 8 - int.parse(notation[1]);
    return Offset(file.toDouble(), rank.toDouble());
  }

  String getPromotionPieceImage(String piece, chess.Color color) {
    final prefix = color == chess.Color.WHITE ? 'w' : 'b';
    return 'assets/pieces/$prefix$piece.png';
  }

  Map<String, dynamic> parseMessage(dynamic data) {
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      ChessScreenState.logger.e("Error parsing message: $e");
      return {}; // return empty map if it fails
    }
  }
}
