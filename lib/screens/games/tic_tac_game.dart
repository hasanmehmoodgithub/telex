import 'package:flutter/material.dart';

class ApprovalDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevents back navigation
      child: Scaffold(
        backgroundColor: Colors.black54, // 0.5 opacity
        body: Center(
          child: AlertDialog(
            backgroundColor: Colors.white,
            content: Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Please wait for admin approval or verification to proceed. For further inquiries, contact us at telex_support@gmail.com.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            actions: <Widget>[
            ],
          ),
        ),
      ),
    );
  }
}
// lib/game.dart


class Game {
  List<String> board;
  String currentPlayer;
  String winner;

  Game()
      : board = List.filled(9, ''),
        currentPlayer = 'X',
        winner = '';

  void makeMove(int index) {
    if (board[index].isEmpty && winner.isEmpty) {
      board[index] = currentPlayer;
      if (checkWinner()) {
        winner = currentPlayer;
      } else {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
      }
    }
  }

  bool checkWinner() {
    const winningCombinations = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    for (var combination in winningCombinations) {
      if (board[combination[0]] == currentPlayer &&
          board[combination[1]] == currentPlayer &&
          board[combination[2]] == currentPlayer) {
        return true;
      }
    }
    return false;
  }

  void reset() {
    board.fillRange(0, 9, '');
    currentPlayer = 'X';
    winner = '';
  }
}

class TicTacToeGame extends StatefulWidget {
  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late Game game;

  @override
  void initState() {
    super.initState();
    game = Game();
  }

  void handleTap(int index) {
    setState(() {
      game.makeMove(index);
    });
  }

  void handleReset() {
    setState(() {
      game.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic Tac Toe'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => handleTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        game.board[index],
                        style: TextStyle(fontSize: 64, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          if (game.winner.isNotEmpty)
            Text(
              '${game.winner} Wins!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ElevatedButton(
            onPressed: handleReset,
            child: Text('Restart Game'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}