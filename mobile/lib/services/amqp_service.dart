import 'dart:async';
import 'dart:convert';
import 'package:dart_amqp/dart_amqp.dart';

class AmqpService {
  final String gameId;
  final String playerSymbol;
  final String playerId;

  late Client _client;
  Channel? _channel;

  AmqpService({
    required this.gameId,
    required this.playerSymbol,
    required this.playerId,
  });

  Future<void> connect() async {
    _client = Client(
      settings: ConnectionSettings(
        host: '192.168.0.174',
        port: 5672,
        authProvider: const PlainAuthenticator('guest', 'guest'),
      ),
    );

    _channel = await _client.channel();
  }

  Future<void> sendMove(int position) async {
    final move = {
      "gameId": gameId,
      "position": position,
      "symbol": playerSymbol,
      "playerId": playerId,
    };

    final envelope = {
      "message": move,
      "messageType": ["urn:message:TicTacToe.Messages:MakeMoveCommand"],
    };

    final payload = utf8.encode(jsonEncode(envelope));

    final exchange = await _channel!.exchange(
      "TicTacToe.Messages:MakeMoveCommand",
      ExchangeType.FANOUT,
      durable: true,
    );

    exchange.publish(payload, "");
  }

  StreamSubscription<AmqpMessage>? _updateSubscription;

  Future<void> subscribeToGameUpdates(
    Function(Map<String, dynamic>) onUpdate,
  ) async {
    final updatesExchange = await _channel!.exchange(
      "TicTacToe.Messages:GameUpdated",
      ExchangeType.FANOUT,
      durable: true,
    );

    final queue = await _channel!.queue(
      '',
      durable: false,
      exclusive: true,
      autoDelete: true,
    );
    await queue.bind(updatesExchange, "");

    final updateConsumer = await queue.consume();
    _updateSubscription = updateConsumer.listen((AmqpMessage message) {
      try {
        final decodedJson =
            jsonDecode(message.payloadAsString) as Map<String, dynamic>;
        final gameData = decodedJson['message'] as Map<String, dynamic>;
        onUpdate(gameData);
      } catch (e) {
        print("Failed to decode game update: $e");
      }
    });
  }

  Future<void> dispose() async {
    await _updateSubscription?.cancel();
    await _client.close();
  }
}
