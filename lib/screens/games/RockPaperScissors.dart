// lib/rock_paper_scissors.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:telex/common/responsive_widget.dart';

class RockPaperScissors extends StatefulWidget {
  @override
  _RockPaperScissorsState createState() => _RockPaperScissorsState();
}

class _RockPaperScissorsState extends State<RockPaperScissors> {
  String userChoice = '';
  String computerChoice = '';
  String result = '';

  void playGame(String choice) {
    userChoice = choice;
    computerChoice = ['Rock', 'Paper', 'Scissors'][Random().nextInt(3)];
    setState(() {
      result = determineWinner();
    });
  }

  String determineWinner() {
    if (userChoice == computerChoice) return 'It\'s a Tie!';
    if ((userChoice == 'Rock' && computerChoice == 'Scissors') ||
        (userChoice == 'Scissors' && computerChoice == 'Paper') ||
        (userChoice == 'Paper' && computerChoice == 'Rock')) {
      return 'You Win!';
    }
    return 'You Lose!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rock, Paper, Scissors'),
      ),
      body: ResponsiveWidget(
        maxWidth: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Choice: $userChoice',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Computer\'s Choice: $computerChoice',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              result,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => playGame('Rock'), child: Text('Rock')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: () => playGame('Paper'), child: Text('Paper')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: () => playGame('Scissors'), child: Text('Scissors')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
