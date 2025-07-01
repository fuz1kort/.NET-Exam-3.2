import 'package:flutter/material.dart';
import '../models/game_dto.dart';

import '../services/api_service.dart';
import 'game_view.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final api = ApiService();
  final _gameIdController = TextEditingController();
  bool _loading = false;
  String? _createdGameId;
  late Future<List<GameDto>> _availableGamesFuture;

  @override
  void initState() {
    super.initState();
    _availableGamesFuture = api.getAvailableGames();
  }

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  void _onCreatePressed() async {
    setState(() {
      _loading = true;
      _createdGameId = null;
    });

    try {
      final gameId = await api.createGame();
      setState(() {
        _createdGameId = gameId;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Игра создана! Game ID: $gameId')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания игры: $e')));
    } finally {
      setState(() {
        _loading = false;
        if (_createdGameId != null) {
          _gameIdController.text = _createdGameId!;
        }
      });
    }
  }

  void _onJoinPressed() async {
    final gameId = _gameIdController.text.trim();
    if (gameId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите Game ID')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await api.joinGame(gameId);
      final playerSymbol = response['playerSymbol'] as String;
      final playerId = response['playerId'] as String;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => GameView(
                gameId: gameId,
                playerSymbol: playerSymbol,
                playerId: playerId,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка подключения: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic-Tac-Toe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _onCreatePressed,
              child: const Text('Создать новую игру'),
            ),
            if (_createdGameId != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Game ID: $_createdGameId\nПоделитесь этим кодом с другом',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            TextField(
              controller: _gameIdController,
              decoration: const InputDecoration(
                labelText: 'Game ID для подключения',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _onJoinPressed,
              child: const Text('Подключиться к игре'),
            ),
            if (_loading) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  _loading
                      ? null
                      : () {
                        setState(() {
                          _availableGamesFuture = api.getAvailableGames();
                        });
                      },
              child: const Text('Обновить список'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<GameDto>>(
                future: _availableGamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Ошибка загрузки игр: ${snapshot.error}'),
                    );
                  }
                  final games = snapshot.data ?? [];
                  if (games.isEmpty) {
                    return const Center(
                      child: Text('Нет доступных игр для подключения'),
                    );
                  }
                  return ListView.separated(
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return ListTile(
                        title: Text('Игра ID: ${game.gameId}'),
                        subtitle: Text(
                          'Игроки: ${game.playerX != null ? 'X назначен' : 'X свободен'}, '
                          '${game.playerO != null ? 'O назначен' : 'O свободен'}',
                        ),
                        trailing: ElevatedButton(
                          child: const Text('Присоединиться'),
                          onPressed: () {
                            _gameIdController.text = game.gameId;
                            _onJoinPressed();
                          },
                        ),
                      );
                    },
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
