import 'package:flutter/material.dart';
import 'views/join_game_view.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const JoinGamePage(),
    );
  }
}
