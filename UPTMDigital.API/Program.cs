// Program.cs
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using UPTMDigital.API.Data;


var builder = WebApplication.CreateBuilder(args);

// 1. Conexión a la base de datos (App - Render / Supabase en producción)
builder.Services.AddDbContext<UPTMDigitalContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 1.1 Conexión a la Base Maestro de Nómina (PC Local o Mirror)
var useMirror = builder.Configuration.GetValue<bool>("NominaConfig:UseMirrorMode");
var nominaConnStr = useMirror
    ? builder.Configuration.GetConnectionString("DefaultConnection")
    : builder.Configuration.GetConnectionString("NominaConnection");

builder.Services.AddDbContext<NominaContext>(options =>
    options.UseNpgsql(nominaConnStr));

// 2. Configuración JWT
var key = Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]
    ?? "MiClaveSuperSecretaDe32Caracteres1234");

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
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 3.1 CORS (Permitir todo para desarrollo)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyMethod()
                   .AllowAnyHeader();
        });
});

var app = builder.Build();

// 4. Middlewares
app.UseCors("AllowAll");

// Swagger habilitado en todos los entornos (staging/producción en Somee)
app.UseSwagger();
app.UseSwaggerUI();

// app.UseHttpsRedirection();

// 5. AUTENTICACIÓN Y AUTORIZACIÓN (orden importante)
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// SEEDING AUTOMÁTICO REMOVED TO PREVENT DATA LOSS
// Use /api/setup/apply-changes endpoint instead.

// Render asigna dinámicamente el puerto mediante la variable de entorno PORT
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
app.Run($"http://0.0.0.0:{port}");
