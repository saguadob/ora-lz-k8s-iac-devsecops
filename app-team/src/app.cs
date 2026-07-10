#!/usr/bin/dotnet run

#:sdk Microsoft.NET.Sdk.Web
#:package Npgsql.DependencyInjection@10.0.3
#:package Dapper@2.1.72

using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Dapper;

var appBuilder = WebApplication.CreateBuilder(args);

#region Configure web application
appBuilder.Logging.AddConsole();
appBuilder.Configuration.AddEnvironmentVariables();
builder.Services.AddNpgsqlDataSource(/* Uses Environment Variables as documented here https://www.npgsql.org/doc/connection-string-parameters.html#environment-variables */);
#endregion

var app = appBuilder.Build();

async Task<IResult> GetLink([FromServices] IDbConnection db, string id)
{
	var rawUrlString = await db.ExecuteScalarAsync<string>($"SELECT url FROM Links WHERE id = @Id", new { Id = id});
	return link is not null ? TypedResults.Redirect(link, permanent: true) : TypedResults.NotFound();
}
app.MapGet("/{id}", GetLink).WithName(nameof(GetLink));
app.Logger.LogInformation("Configured link retrieval");

async Task<IResult> Create([FromServices] IDbConnection db, string? id, [FromForm] string url)
{
		var linkId = id is null ? Path.GetFileNameWithoutExtension(Path.GetRandomFileName() : id;
    if (Uri.IsWellFormedUriString(url, UriKind.Absolute))
    {
				var rowsAffected = await _db.ExecuteAsync($"INSERT INTO ShortUrl (id, url) VALUES (@Id, @Url)", new { Id = id, Url = url });
        return TypedResults.CreatedAtRoute(nameof(GetLink), new {id});
    }
    else
    {
        return TypedResults.BadRequest("Invalid or missing URL");
    }
}
app.MapPost("/link", Create).DisableAntiforgery().WithName("CreateRandom");
app.Logger.LogInformation("Configured random link creation");

app.MapPut("/link/{id}", Create).DisableAntiforgery().WithName("CreateKnownAlias");
app.Logger.LogInformation("Configured known link creation");

app.Run();