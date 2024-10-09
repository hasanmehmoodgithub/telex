import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:telex/screens/games/GameWebView.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class GamesListScreen extends StatelessWidget {
  // Sample list of games with title, description, and image URL
  final List<GameItem> games = [
    GameItem(
      title: '2048 Game',
      description: 'A classic sliding puzzle game.',
      imageUrl: 'https://lh3.googleusercontent.com/ZV0IXSCwUofCS6RabwNJ_yp4vwcxEenGYwscnbWtESd-6xt7JYRc6-PpWJAXUtbhJC74SCDt6970NS1ftvHTeC47XGE=s1280-w1280-h800',
      route: "https://2048game.com/",
      isWeb: true,

    ),
    GameItem(
      title: 'Slither',
      description: 'A multiplayer snake game where you grow by eating pellets.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGISxiI_8sIUrXibA_JVa3HeA5IWE992n4eqYHpIW-f_lkco0wTbTz1FwVXQVMHC-gaO_F',
      route: "http://slither.com/io",
      isWeb: true,

    ),

    GameItem(
      title: 'Tic Tac',
      description: 'A fun and classic Tic Tac Toe game.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvJfxpuYWduSr-NjJN9q816fAquJVfzcOkyg&s',
      route: "tictac",
      isWeb: false,

    ),
    GameItem(
      title: 'Rock-Paper-Scissors',
      description: 'RockPaper is a simple and fun game where players choose between three options: Rock, Paper, or Scissors. ',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuiK2NTJMDZXmp-1jblSngtYuMKDW6qcKHWQ&s',
      route: "rockpaper",
      isWeb: false,
    ),
    GameItem(
        title: 'Four in a Row: Classic Strategy Game',
        description: '''Step into the world of Four in a Row, an engaging and strategic game where players compete to connect four discs in a row before their opponent does! Set on a dynamic 7-column grid, this game challenges players to think ahead, strategize, and block their opponent's moves while aiming for victory.''',
    imageUrl: "https://www.switchedonkids.com.au/wp-content/uploads/2017/07/4-in-a-row-M-size-four-in-a-row-line-connecting-bingo-board-game-interactive-1.jpg",
        route: "FourInARowApp",
      isWeb: false,
    ),
    // Add more games here
  ];
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Games List'),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return InkWell(
            onTap: (){
              if(game.isWeb)
                {
                  if (kIsWeb){
                    _launchURL(game.route);

                  }
                  else{
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GameWebView(url: game.route,title: game.title,))
                    );
                  }

                }
              else{
                Navigator.pushNamed(context, "/${game.route}");
              }


            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cached network image with height and BoxFit.cover
                    CachedNetworkImage(
                      imageUrl: game.imageUrl,
                      height: 200, // Fixed height for the image
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error, size: 50),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        game.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        game.description,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GameItem {
  final String title;
  final String description;
  final String imageUrl;
  final String route;
  final bool isWeb;
  GameItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.route,
    required this.isWeb,
  });
}
