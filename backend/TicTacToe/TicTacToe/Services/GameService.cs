using System.Collections.Concurrent;
using MassTransit;
using TicTacToe.DTO;
using TicTacToe.Messages;
using TicTacToe.Models;

namespace TicTacToe.Services;

public class GameService
{
    private readonly ConcurrentDictionary<Guid, Game> _games = new();
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<GameService> _logger;

    // ReSharper disable once NotAccessedField.Local
    private readonly Timer _cleanupTimer;

    public GameService(IServiceScopeFactory scopeFactory, ILogger<GameService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;

        _cleanupTimer = new Timer(CleanupGames, null, TimeSpan.Zero, TimeSpan.FromMinutes(5));
    }

    public void CreateGame(Guid gameId)
    {
        _logger.LogInformation("Creating new game with ID: {GameId}", gameId);
        _games[gameId] = new Game { GameId = gameId };
        _logger.LogInformation("Game created with ID: {GameId}", gameId);
    }

    public IEnumerable<GameDto> GetAvailableGames()
    {
        return _games
            .Where(g => (g.Value.PlayerX == null || g.Value.PlayerO == null) && !g.Value.IsFinished)
            .Select(g => new GameDto
            {
                GameId = g.Value.GameId,
                PlayerX = g.Value.PlayerX,
                PlayerO = g.Value.PlayerO
            })
            .ToList();
    }

    public GameUpdated MakeMove(Guid gameId, int position, string symbol, Guid playerId)
    {
        _logger.LogInformation("Player {Symbol} (ID: {PlayerId}) makes move at position {Position} in game {GameId}",
            symbol, playerId, position, gameId);

        if (!_games.TryGetValue(gameId, out var game))
        {
            _logger.LogWarning("Game with ID {GameId} not found", gameId);
            throw new Exception("Game not found");
        }

        if (game.PlayerX == null || game.PlayerO == null)
        {
            throw new Exception("Not enough players to start the game");
        }

        if (game.IsFinished)
        {
            _logger.LogWarning("Attempt to move in finished game {GameId}", gameId);
            throw new Exception("Game is already finished");
        }

        if ((symbol == "X" && game.PlayerX != playerId) || (symbol == "O" && game.PlayerO != playerId))
        {
            _logger.LogWarning("Invalid player {PlayerId} attempted to move in game {GameId}", playerId, gameId);
            throw new Exception("You cannot move as another player");
        }

        if (game.CurrentPlayer != symbol)
        {
            _logger.LogWarning("Not player {Symbol}'s turn (ID: {PlayerId}) in game {GameId}", symbol, playerId,
                gameId);
            throw new Exception("Not your turn");
        }

        if (position < 0 || position >= 9 || !string.IsNullOrEmpty(game.Board[position]))
        {
            _logger.LogWarning(
                "Invalid move by player {Symbol} (ID: {PlayerId}) at position {Position} in game {GameId}",
                symbol, playerId, position, gameId);
            throw new Exception("Invalid move");
        }

        game.Board[position] = symbol;

        var wins = new[]
        {
            new[] { 0, 1, 2 }, new[] { 3, 4, 5 }, new[] { 6, 7, 8 },
            new[] { 0, 3, 6 }, new[] { 1, 4, 7 }, new[] { 2, 5, 8 },
            new[] { 0, 4, 8 }, new[] { 2, 4, 6 }
        };

        if (wins.Any(line => line.All(i => game.Board[i] == symbol)))
        {
            game.Winner = symbol;
            _logger.LogInformation("Player {Symbol} (ID: {PlayerId}) won game {GameId}", symbol, playerId, gameId);
        }

        if (!game.IsFinished)
        {
            game.CurrentPlayer = symbol == "X" ? "O" : "X";
            _logger.LogInformation("Next turn: player {NextPlayer} in game {GameId}", game.CurrentPlayer, gameId);
        }
        else
        {
            _logger.LogInformation("Game {GameId} is finished", gameId);
            _games.Remove(gameId, out _);
        }

        return new GameUpdated
        {
            GameId = game.GameId,
            Board = game.Board,
            CurrentPlayer = game.CurrentPlayer,
            Winner = game.Winner,
            IsFinished = game.IsFinished,
            PlayerX = game.PlayerX,
            PlayerO = game.PlayerO
        };
    }

    public Game? GetGameById(Guid gameId)
    {
        _logger.LogInformation("Getting game with ID: {GameId}", gameId);
        return _games.GetValueOrDefault(gameId);
    }

    public void LeaveGame(Guid gameId, Guid playerId)
    {
        var game = GetGameById(gameId);
        if (game == null)
        {
            _logger.LogWarning("Attempt to leave non-existent game {GameId}", gameId);
            return;
        }

        if (game.PlayerX == playerId)
        {
            game.PlayerX = null;
            _logger.LogInformation("Player X with ID {PlayerId} left game {GameId}", playerId, gameId);
        }
        else if (game.PlayerO == playerId)
        {
            game.PlayerO = null;
            _logger.LogInformation("Player O with ID {PlayerId} left game {GameId}", playerId, gameId);
        }
        else
        {
            _logger.LogWarning("Player with ID {PlayerId} not found in game {GameId}", playerId, gameId);
            return;
        }

        if (game.PlayerX == null && game.PlayerO == null)
        {
            _games.Remove(gameId, out _);
            _logger.LogInformation("Game {GameId} removed due to no players remaining", gameId);
        }

        using var scope = _scopeFactory.CreateScope();
        var publishEndpoint = scope.ServiceProvider.GetRequiredService<IPublishEndpoint>();

        publishEndpoint.Publish(new GameUpdated
        {
            GameId = game.GameId,
            Board = game.Board,
            CurrentPlayer = game.CurrentPlayer,
            Winner = game.Winner,
            IsFinished = game.IsFinished,
            PlayerX = game.PlayerX,
            PlayerO = game.PlayerO
        });
    }

    public (string? PlayerSymbol, Guid? PlayerId) AssignPlayerSymbol(Guid gameId)
    {
        var game = GetGameById(gameId);
        if (game == null) return (null, null);

        using var scope = _scopeFactory.CreateScope();
        var publishEndpoint = scope.ServiceProvider.GetRequiredService<IPublishEndpoint>();

        if (game.PlayerX == null)
        {
            var playerId = Guid.NewGuid();
            game.PlayerX = playerId;

            publishEndpoint.Publish(new GameUpdated
            {
                GameId = gameId,
                Board = game.Board,
                CurrentPlayer = game.CurrentPlayer,
                Winner = game.Winner,
                IsFinished = game.IsFinished,
                PlayerX = game.PlayerX,
                PlayerO = game.PlayerO
            });

            return ("X", playerId);
        }

        if (game.PlayerO == null)
        {
            var playerId = Guid.NewGuid();
            game.PlayerO = playerId;

            publishEndpoint.Publish(new GameUpdated
            {
                GameId = gameId,
                Board = game.Board,
                CurrentPlayer = game.CurrentPlayer,
                Winner = game.Winner,
                IsFinished = game.IsFinished,
                PlayerX = game.PlayerX,
                PlayerO = game.PlayerO
            });

            return ("O", playerId);
        }

        return (null, null);
    }

    private void CleanupGames(object? state)
    {
        var gamesToRemove = _games
            .Where(kvp => kvp.Value.PlayerX == null && kvp.Value.PlayerO == null)
            .Select(kvp => kvp.Key)
            .ToList();

        foreach (var gameId in gamesToRemove)
        {
            _games.Remove(gameId, out _);
            _logger.LogInformation("Removed empty game {GameId}", gameId);
        }
    }
}