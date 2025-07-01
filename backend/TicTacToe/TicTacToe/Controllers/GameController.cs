using Microsoft.AspNetCore.Mvc;
using TicTacToe.Services;

namespace TicTacToe.Controllers;

[ApiController]
[Route("api/[controller]")]
public class GameController(GameService gameService) : ControllerBase
{
    [HttpGet("available")]
    public IActionResult GetAvailableGames()
    {
        var availableGames = gameService.GetAvailableGames();
        return Ok(availableGames);
    }

    [HttpPost("create")]
    public IActionResult CreateGame()
    {
        var gameId = Guid.NewGuid();
        gameService.CreateGame(gameId);
        return Ok(new { GameId = gameId });
    }

    [HttpGet("{gameId:guid}")]
    public IActionResult GetGame(Guid gameId)
    {
        var game = gameService.GetGameById(gameId);
        return game is null ? NotFound("Game not found") : Ok(game);
    }

    [HttpPost("{gameId:guid}/join")]
    public IActionResult JoinGame(Guid gameId)
    {
        var (playerSymbol, playerId) = gameService.AssignPlayerSymbol(gameId);

        if (playerSymbol == null || playerId == null)
        {
            return BadRequest("Игра не найдена или уже полна");
        }

        return Ok(new { playerSymbol, playerId });
    }

    [HttpPost("{gameId:guid}/leave")]
    public IActionResult LeaveGame(Guid gameId, [FromQuery] Guid playerId)
    {
        gameService.LeaveGame(gameId, playerId);
        return Ok();
    }
}