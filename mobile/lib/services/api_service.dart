import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';
import '../models/game_dto.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://192.168.0.174:5000/api'});

  Future<String> createGame() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/Game/create'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['gameId'];
      } else {
        throw Exception(
          'Failed to create game. Status code: ${res.statusCode}',
        );
      }
    } catch (e) {
      print('Error in createGame: $e');
      rethrow;
    }
  }

  Future<Game> getGame(String gameId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Game/$gameId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return Game.fromJson(data);
      } else {
        throw Exception('Failed to get game. Status code: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getGame: $e');
      rethrow;
    }
  }

  Future<List<GameDto>> getAvailableGames() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Game/available'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((json) => GameDto.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to get available games. Status code: ${res.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getAvailableGames: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> joinGame(String gameId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/Game/$gameId/join'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data.containsKey('playerSymbol') && data.containsKey('playerId')) {
          return {
            'playerSymbol': data['playerSymbol'] as String,
            'playerId': data['playerId'] as String,
          };
        } else {
          throw Exception(
            'Invalid response from server: missing required fields',
          );
        }
      } else {
        throw Exception('Failed to join game. Status code: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in joinGame: $e');
      rethrow;
    }
  }

  Future<void> leaveGame(String gameId, String playerId) async {
    final url = Uri.parse('$baseUrl/Game/$gameId/leave?playerId=$playerId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to notify server about leaving the game');
    }
  }
}
