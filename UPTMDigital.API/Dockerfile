# Usa la imagen del SDK de .NET 9.0 para compilar la aplicación
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copia el archivo csproj y restaura las dependencias
COPY ["UPTMDigital.API.csproj", "./"]
RUN dotnet restore "UPTMDigital.API.csproj"

# Copia el resto de los archivos y genera la publicación
COPY . .
RUN dotnet publish "UPTMDigital.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Usa la imagen del runtime de ASP.NET Core 9.0 para ejecutar la aplicación
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Render inyecta la variable de entorno PORT. El binding se hace en Program.cs.
ENTRYPOINT ["dotnet", "UPTMDigital.API.dll"]
