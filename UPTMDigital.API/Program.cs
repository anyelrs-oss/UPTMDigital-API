// Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Reflection;
using System.Text;
using UPTMDigital.API.Data;


var builder = WebApplication.CreateBuilder(args);
var isDevelopment = builder.Environment.IsDevelopment();

// Fix for Supabase / PostgreSQL pooler IPv6 timeout issues in Render
AppContext.SetSwitch("System.Net.DisableIPv6", true);

var dbCommandTimeoutSeconds = builder.Configuration.GetValue<int?>("DatabaseResilience:CommandTimeoutSeconds") ?? 45;
var dbMaxRetryCount = builder.Configuration.GetValue<int?>("DatabaseResilience:MaxRetryCount") ?? 6;
var dbMaxRetryDelaySeconds = builder.Configuration.GetValue<int?>("DatabaseResilience:MaxRetryDelaySeconds") ?? 15;
var dbConnectionTimeoutSeconds = builder.Configuration.GetValue<int?>("DatabaseResilience:ConnectionTimeoutSeconds") ?? 15;
var dbKeepAliveSeconds = builder.Configuration.GetValue<int?>("DatabaseResilience:KeepAliveSeconds") ?? 30;
var dbMinPoolSize = builder.Configuration.GetValue<int?>("DatabaseResilience:MinPoolSize") ?? 0;
var dbMaxPoolSize = builder.Configuration.GetValue<int?>("DatabaseResilience:MaxPoolSize") ?? 30;

string BuildResilientConnectionString(string connectionString)
{
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        return connectionString;
    }

    var csb = new NpgsqlConnectionStringBuilder(connectionString)
    {
        Timeout = dbConnectionTimeoutSeconds,
        CommandTimeout = dbCommandTimeoutSeconds,
        KeepAlive = dbKeepAliveSeconds,
        Pooling = true,
        MinPoolSize = dbMinPoolSize,
        MaxPoolSize = dbMaxPoolSize,
    };

    return csb.ConnectionString;
}

void ConfigurePostgres(DbContextOptionsBuilder options, string connectionString)
{
    var tunedConnectionString = BuildResilientConnectionString(connectionString);

    options.UseNpgsql(tunedConnectionString, npgsqlOptions =>
    {
        // Retry transient network and pooler hiccups common in cloud-hosted Postgres.
        npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: dbMaxRetryCount,
            maxRetryDelay: TimeSpan.FromSeconds(dbMaxRetryDelaySeconds),
            errorCodesToAdd: null);
        npgsqlOptions.CommandTimeout(dbCommandTimeoutSeconds);
    });
}

// 1. Conexión a la base de datos (App - Render / Supabase en producción)
builder.Services.AddDbContext<UPTMDigitalContext>(options =>
    ConfigurePostgres(options, builder.Configuration.GetConnectionString("DefaultConnection") ?? string.Empty));

// 1.1 Conexión a la Base Maestro de Nómina (PC Local o Mirror)
var useMirror = builder.Configuration.GetValue<bool>("NominaConfig:UseMirrorMode");
var nominaConnStr = useMirror
    ? builder.Configuration.GetConnectionString("DefaultConnection")
    : builder.Configuration.GetConnectionString("NominaConnection");

builder.Services.AddDbContext<NominaContext>(options =>
    ConfigurePostgres(options, nominaConnStr ?? string.Empty));

// 2. Configuración JWT
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrEmpty(jwtKey))
{
    jwtKey = "MiClaveSuperSecretaDe32Caracteres1234";
}
var key = Encoding.UTF8.GetBytes(jwtKey);

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
});

// 3. Servicios estándar
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 3.0 Render / reverse proxy support
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

// 3.1 CORS
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCors", policy =>
    {
        if (allowedOrigins.Length == 0)
        {
            // Fallback for quick local setup.
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
            return;
        }

        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

static bool IsTransientDbException(Exception ex)
{
    if (ex is TimeoutException || ex is NpgsqlException)
    {
        return true;
    }

    if (ex is InvalidOperationException && ex.InnerException is NpgsqlException)
    {
        return true;
    }

    return ex.InnerException is TimeoutException || ex.InnerException is NpgsqlException;
}

// 4. Middlewares
app.UseForwardedHeaders();

if (isDevelopment)
{
    app.UseDeveloperExceptionPage();
}

// Return a controlled 503 for transient DB failures instead of exposing 500 stack traces.
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception ex)
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(new
        {
            message = "Unhandled Exception Debug Info",
            error = ex.Message,
            stack = ex.ToString()
        });
    }
});

app.UseCors("DefaultCors");

// Swagger habilitado en todos los entornos (staging/producción en Somee)
app.UseSwagger();
app.UseSwaggerUI();

if (!isDevelopment)
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

// 5. AUTENTICACIÓN Y AUTORIZACIÓN (orden importante)
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok", env = app.Environment.EnvironmentName }));
app.MapGet("/api/health", () => Results.Ok(new { status = "ok", env = app.Environment.EnvironmentName }));
app.MapGet("/api/version", () => Results.Ok(new
{
    app = "UPTMDigital.API",
    environment = app.Environment.EnvironmentName,
    version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown",
    features = new[]
    {
        "db-resilience",
        "transient-db-503",
        "setup-seed-test-users"
    }
}));

// SEEDING AUTOMÁTICO REMOVED TO PREVENT DATA LOSS
// Use /api/setup/apply-changes endpoint instead.

// Render asigna dinámicamente el puerto mediante la variable de entorno PORT
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
app.Run($"http://0.0.0.0:{port}");
