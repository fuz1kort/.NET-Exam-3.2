class GameDto {
  final String gameId;
  String? playerX;
  String? playerO;

  GameDto({required this.gameId, this.playerX, this.playerO});

  factory GameDto.fromJson(Map<String, dynamic> json) {
    return GameDto(
      gameId: json['gameId'],
      playerX: json['playerX'],
      playerO: json['playerO'],
    );
  }
}
