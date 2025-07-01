import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/amqp_service.dart';
import '../services/api_service.dart';

class GameView extends StatefulWidget {
  final String gameId;
  final String playerSymbol;
  final String playerId;

  const GameView({
    super.key,
    required this.gameId,
    required this.playerSymbol,
    required this.playerId,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final api = ApiService();
  late AmqpService amqp;
  Game? game;
  bool loading = false;
  late String playerId;

  @override
  void initState() {
    super.initState();
    amqp = AmqpService(
      gameId: widget.gameId,
      playerSymbol: widget.playerSymbol,
      playerId: widget.playerId,
    );

    amqp.connect().then((_) {
      amqp.subscribeToGameUpdates((updateJson) {
        final updatedGame = Game.fromJson(updateJson);
        if (mounted) {
          setState(() {
            game = updatedGame;
            if (updatedGame.playerX != null) {
              game?.playerX = updatedGame.playerX;
            } else if (updatedGame.playerO != null) {
              game?.playerO = updatedGame.playerO;
            }
          });
        }
      });
    });

    fetchGame();
  }

  Future<void> fetchGame() async {
    final result = await api.getGame(widget.gameId);
    setState(() {
      game = result;
    });
  }

  Future<void> handleTap(int index) async {
    if (game == null ||
        game!.board[index].isNotEmpty ||
        game!.isFinished ||
        game!.playerX == null ||
        game!.playerO == null) {
      return;
    }
    if (game!.currentPlayer != widget.playerSymbol) return;

    await amqp.sendMove(index);
  }

  Widget buildCell(int index) {
    return GestureDetector(
      onTap: () => handleTap(index),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        alignment: Alignment.center,
        child: Text(
          game?.board[index] ?? '',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String playerXLabel = game!.playerX == widget.playerId ? 'Ты' : 'Соперник';
    String playerOLabel = game!.playerO == widget.playerId ? 'Ты' : 'Соперник';

    return Scaffold(
      appBar: AppBar(
        title: Text("Игра ${game!.gameId}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            try {
              await api.leaveGame(widget.gameId, widget.playerId);
            } catch (e) {
              print('Ошибка при выходе из игры: $e');
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Игрок X: ${game!.playerX != null ? playerXLabel : 'Не назначен'}",
          ),
          Text(
            "Игрок O: ${game!.playerO != null ? playerOLabel : 'Не назначен'}",
          ),
          const SizedBox(height: 10),
          Text("Текущий игрок: ${game!.currentPlayer}"),
          if (game!.isFinished)
            Text(
              game!.winner.isNotEmpty ? "Победитель: ${game!.winner}" : "Ничья",
            ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (_, i) => buildCell(i),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amqp.dispose();
    super.dispose();
  }
}
