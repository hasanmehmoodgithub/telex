// lib/snake_game.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SnakeGame extends StatefulWidget {
  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final int gridSize = 20;
  final List<int> snake = [0, 1, 2]; // Initial snake positions
  int food = 0;
  String direction = 'right';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    spawnFood();
    startGame();
  }

  void startGame() {
    timer = Timer.periodic(Duration(milliseconds: 200), (Timer timer) {
      moveSnake();
    });
  }

  void moveSnake() {
    setState(() {
      int newHead;
      switch (direction) {
        case 'up':
          newHead = snake.first - gridSize;
          break;
        case 'down':
          newHead = snake.first + gridSize;
          break;
        case 'left':
          newHead = snake.first - 1;
          break;
        case 'right':
          newHead = snake.first + 1;
          break;
        default:
          return;
      }

      // Check for collisions with the wall or itself
      if (newHead < 0 ||
          newHead >= gridSize * gridSize ||
          (direction == 'left' && newHead % gridSize == gridSize - 1) ||
          (direction == 'right' && newHead % gridSize == 0) ||
          snake.contains(newHead)) {
        timer?.cancel();
        showGameOverDialog();
      } else {
        snake.insert(0, newHead); // Add new head to the snake
        if (newHead == food) {
          spawnFood(); // Spawn new food
        } else {
          snake.removeLast(); // Remove the tail if not eating
        }
      }
    });
  }

  void spawnFood() {
    Random random = Random();
    do {
      food = random.nextInt(gridSize * gridSize);
    } while (snake.contains(food));
  }

  void changeDirection(String newDirection) {
    // Prevent reversing direction
    if ((direction == 'up' && newDirection != 'down') ||
        (direction == 'down' && newDirection != 'up') ||
        (direction == 'left' && newDirection != 'right') ||
        (direction == 'right' && newDirection != 'left')) {
      direction = newDirection;
    }
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game Over'),
        content: Text('Your score is: ${snake.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      snake.clear();
      snake.addAll([0, 1, 2]);
      spawnFood();
      direction = 'right';
      startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < 0) {
            changeDirection('up');
          } else if (details.delta.dy > 0) {
            changeDirection('down');
          }
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < 0) {
            changeDirection('left');
          } else if (details.delta.dx > 0) {
            changeDirection('right');
          }
        },
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            Color color;
            if (snake.contains(index)) {
              color = Colors.green;
            } else if (index == food) {
              color = Colors.red;
            } else {
              color = Colors.grey[300]!;
            }
            return Container(
              margin: EdgeInsets.all(1.0),
              color: color,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
