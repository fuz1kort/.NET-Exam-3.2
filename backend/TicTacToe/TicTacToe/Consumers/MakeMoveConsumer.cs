using MassTransit;
using TicTacToe.Messages;
using TicTacToe.Services;

namespace TicTacToe.Consumers;

public class MakeMoveConsumer(GameService gameService, IPublishEndpoint publishEndpoint, ILogger<MakeMoveConsumer> logger)
    : IConsumer<MakeMoveCommand>
{
    public async Task Consume(ConsumeContext<MakeMoveCommand> context)
    {
        var command = context.Message;
        logger.LogInformation("Move: GameId={GameId}, Pos={Position}, Symbol={Symbol}",
            command.GameId, command.Position, command.Symbol);

        try
        {
            var update = gameService.MakeMove(command.GameId, command.Position, command.Symbol, command.PlayerId);
            await publishEndpoint.Publish(update);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Move failed");
        }
    }
}