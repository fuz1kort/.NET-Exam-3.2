namespace TicTacToe.Models;

public class Game
{
    public Guid GameId { get; set; }
    public string[] Board { get; set; } = Enumerable.Repeat("", 9).ToArray(); // 3x3
    public string CurrentPlayer { get; set; } = "X";
    public string Winner { get; set; } = "";
    public Guid? PlayerX { get; set; }
    public Guid? PlayerO { get; set; }
    public bool IsFinished => !string.IsNullOrEmpty(Winner) || Board.All(c => !string.IsNullOrEmpty(c));
}