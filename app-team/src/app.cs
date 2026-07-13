#!/usr/bin/dotnet run

#:sdk Microsoft.NET.Sdk.Web
#:package Npgsql.DependencyInjection@10.0.3
#:package Dapper@2.1.72
#:package Dapper.AOT@1.0.52
#:property InterceptorsPreviewNamespaces=$(InterceptorsPreviewNamespaces);Dapper.AOT

using Dapper;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

[module: DapperAot]

var appBuilder = WebApplication.CreateBuilder(args);

#region Configure web application
appBuilder.Logging.AddConsole();
appBuilder.Configuration.AddEnvironmentVariables();
appBuilder.Services.AddNpgsqlSlimDataSource(appBuilder.Configuration.GetConnectionString("DefaultConnection")!);
#endregion

var app = appBuilder.Build();

async Task<IResult> GetLink([FromServices] NpgsqlConnection db, string id)
{
	var rawUrlString = await db.ExecuteScalarAsync<string>($"SELECT url FROM Links WHERE id = @Id", new { Id = id});
	return rawUrlString is not null ? TypedResults.Redirect(rawUrlString, permanent: true) : TypedResults.NotFound();
}
app.MapGet("/{id}", GetLink).WithName(nameof(GetLink));
app.Logger.LogInformation("Configured link retrieval");

async Task<IResult> Create([FromServices] NpgsqlConnection db, string? id, [FromForm] string url)
{
		var linkId = id is null ? Path.GetFileNameWithoutExtension(Path.GetRandomFileName()): id;
    if (Uri.IsWellFormedUriString(url, UriKind.Absolute))
    {
				var rowsAffected = await db.ExecuteAsync($"INSERT INTO Links (id, url) VALUES (@Id, @Url)", new { Id = linkId, Url = url });
        return Results.CreatedAtRoute(nameof(GetLink), new RouteValueDictionary { ["id"] = linkId });
    }
    else
    {
        return Results.BadRequest("Invalid or missing URL");
    }
}
app.MapPost("/link", Create).DisableAntiforgery().WithName("CreateRandom");
app.Logger.LogInformation("Configured random link creation");

app.MapPut("/link/{id}", Create).DisableAntiforgery().WithName("CreateKnownAlias");
app.Logger.LogInformation("Configured known link creation");

app.Run();