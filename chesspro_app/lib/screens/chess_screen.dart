import 'package:chesspro_app/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:logger/logger.dart';

void main() {
  runApp(MaterialApp(home: ChessScreen()));
}

class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});

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
                              onDrag(details, position);
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
                                          ? Draggable<String>(
                                            data: pieceAtPosition,
                                            feedback: SizedBox(
                                              width: squareSize,
                                              height: squareSize,
                                              child: Image.asset(
                                                getPieceImage(pieceAtPosition),
                                              ),
                                            ),
                                            childWhenDragging: Container(),
                                            onDragStarted: () {
                                              if (isGameOver) {
                                                return;
                                              }
                                              setState(() {
                                                selectedPiece = pieceAtPosition;
                                              });
                                            },
                                            child: SizedBox(
                                              width: squareSize,
                                              height: squareSize,
                                              child: Image.asset(
                                                getPieceImage(pieceAtPosition),
                                              ),
                                            ),
                                          )
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

  void onDrag(details, position) {
    if (isGameOver) return; // Prevent dragging if the game is over

    String from = _convertToChessNotation(piecePositions[details.data]!);
    String to = _convertToChessNotation(position);

    if (game.move({'from': from, 'to': to})) {
      // Valid move
      setState(() {
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
    if (isGameOver) {
      return;
    }
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
          bool isWhiteTurn = game.turn == chess.Color.WHITE;
          bool isWhitePiece = pieceAtPosition.contains('white');
          if ((isWhiteTurn && !isWhitePiece) ||
              (!isWhiteTurn && isWhitePiece)) {
            return; // Exit early if it's not the player's turn
          }
          selectedPiece = pieceAtPosition;
        }
      } else {
        // Second tap - move the selected piece or select a different piece
        String from = _convertToChessNotation(piecePositions[selectedPiece!]!);
        String to = _convertToChessNotation(Offset(x.toDouble(), y.toDouble()));
        if (game.move({'from': from, 'to': to})) {
          // Valid move
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

  String _convertToChessNotation(Offset position) {
    // Convert board coordinates to chess notation (e.g., (0, 6) -> "a2")
    String file = String.fromCharCode(97 + position.dx.toInt());
    String rank = (8 - position.dy.toInt()).toString();
    return '$file$rank';
  }
}
