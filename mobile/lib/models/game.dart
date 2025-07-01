class Game {
  final String gameId;
  final List<String> board;
  final String currentPlayer;
  final String winner;
  final bool isFinished;
  String? playerX;
  String? playerO;

  Game({
    required this.gameId,
    required this.board,
    required this.currentPlayer,
    required this.winner,
    required this.isFinished,
    this.playerX,
    this.playerO,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['gameId'],
      board: List<String>.from(json['board']),
      currentPlayer: json['currentPlayer'],
      winner: json['winner'],
      isFinished: json['isFinished'],
      playerX: json['playerX'],
      playerO: json['playerO'],
    );
  }
}
