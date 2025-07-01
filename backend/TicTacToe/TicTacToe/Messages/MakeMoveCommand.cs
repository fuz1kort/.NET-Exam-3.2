namespace TicTacToe.Messages;

public record MakeMoveCommand
{
    public Guid GameId { get; init; }
    public int Position { get; init; }
    public string Symbol { get; init; } // 'X' или 'O'
    public Guid PlayerId { get; init; }
}