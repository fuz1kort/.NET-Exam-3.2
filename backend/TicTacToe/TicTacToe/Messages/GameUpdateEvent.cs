namespace TicTacToe.Messages;

public class GameUpdated
{
    public Guid GameId { get; set; }
    public string[] Board { get; set; } = null!;
    public string CurrentPlayer { get; set; } = null!;
    public string Winner { get; set; } = "";
    public bool IsFinished { get; set; }
    public Guid? PlayerX { get; set; }
    public Guid? PlayerO { get; set; }
}