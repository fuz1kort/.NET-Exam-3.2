namespace TicTacToe.DTO;

public class GameDto
{
    public Guid GameId { get; set; }

    public Guid? PlayerX { get; set; }  // null, если игрок X ещё не назначен

    public Guid? PlayerO { get; set; }  // null, если игрок O ещё не назначен
}