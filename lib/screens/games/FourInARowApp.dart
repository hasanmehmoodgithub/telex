import 'package:flutter/material.dart';
import 'package:telex/common/responsive_widget.dart';

class FourInARowApp extends StatefulWidget {
  @override
  _FourInARowAppState createState() => _FourInARowAppState();
}

class _FourInARowAppState extends State<FourInARowApp> {
  static const int rows = 6;
  static const int columns = 7;
  late List<List<int>> board; // 0 = empty, 1 = Player 1, 2 = Player 2
  late int currentPlayer;
  late bool isGameOver;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    // Initialize the game board with empty cells
    board = List.generate(rows, (_) => List.filled(columns, 0));
    currentPlayer = 1;
    isGameOver = false;
  }

  void dropDisc(int column) {
    if (isGameOver) return; // If the game is over, don't allow more moves

    // Find the lowest empty row in the column
    for (int row = rows - 1; row >= 0; row--) {
      if (board[row][column] == 0) {
        setState(() {
          // Place the disc for the current player
          board[row][column] = currentPlayer;

          // Check if the current player has won the game
          if (checkForWin(row, column)) {
            isGameOver = true;
            _showGameOverDialog('Player $currentPlayer Wins!');
          } else {
            // Switch to the other player
            currentPlayer = (currentPlayer == 1) ? 2 : 1;
          }
        });
        return;
      }
    }
  }

  bool checkForWin(int row, int col) {
    // Check for win in all four directions: horizontal, vertical, and two diagonals
    return (checkDirection(row, col, 1, 0) || // Horizontal
        checkDirection(row, col, 0, 1) || // Vertical
        checkDirection(row, col, 1, 1) || // Diagonal \
        checkDirection(row, col, 1, -1)); // Diagonal /
  }

  bool checkDirection(int row, int col, int deltaRow, int deltaCol) {
    int count = 1;

    // Check positive direction (right/upwards)
    for (int i = 1; i < 4; i++) {
      int newRow = row + i * deltaRow;
      int newCol = col + i * deltaCol;
      if (isInBounds(newRow, newCol) && board[newRow][newCol] == currentPlayer) {
        count++;
      } else {
        break;
      }
    }

    // Check negative direction (left/downwards)
    for (int i = 1; i < 4; i++) {
      int newRow = row - i * deltaRow;
      int newCol = col - i * deltaCol;
      if (isInBounds(newRow, newCol) && board[newRow][newCol] == currentPlayer) {
        count++;
      } else {
        break;
      }
    }

    return count >= 4; // Return true if 4 discs in a row are found
  }

  bool isInBounds(int row, int col) {
    // Check if the row and column are within the bounds of the board
    return row >= 0 && row < rows && col >= 0 && col < columns;
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                resetGame(); // Reset the game when the dialog is dismissed
              });
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Four in a Row'),
      ),
      body: ResponsiveWidget(
        maxWidth: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, // 7 columns
                  childAspectRatio: 1.0, // Square cells
                ),
                itemCount: rows * columns, // 6 rows * 7 columns = 42 cells
                itemBuilder: (context, index) {
                  int row = index ~/ columns;
                  int col = index % columns;

                  return GestureDetector(
                    onTap: () => dropDisc(col), // Drop disc in the tapped column
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent),
                        color: board[row][col] == 0
                            ? Colors.white
                            : board[row][col] == 1
                            ? Colors.red
                            : Colors.yellow,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: FourInARowApp()));
