using MassTransit;
using TicTacToe.Consumers;
using TicTacToe.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

var rabbitMqHost = builder.Configuration["RABBITMQ_HOST"] ?? "localhost";
var rabbitMqUsername = builder.Configuration["RABBITMQ_USERNAME"] ?? "guest";
var rabbitMqPassword = builder.Configuration["RABBITMQ_PASSWORD"] ?? "guest";

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<MakeMoveConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host($"rabbitmq://{rabbitMqHost}", h =>
        {
            h.Username(rabbitMqUsername);
            h.Password(rabbitMqPassword);
        });

        cfg.ReceiveEndpoint("make-move-queue", e =>
        {
            e.ConfigureConsumer<MakeMoveConsumer>(context);
        });
    });

});

builder.Services.AddSingleton<GameService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.WebHost.UseUrls("http://0.0.0.0:80");

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.Run();