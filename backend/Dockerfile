# Sport Mate API — multi-stage build. Build context: the backend/ folder.
#   docker build -t sportmate-api ./backend

# ---------- Build ----------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Restore first, from project files only, so package downloads are cached between code changes.
# global.json is left out: the sdk:8.0 image already fixes the SDK version.
COPY SportMate.sln ./
COPY SportMate.Domain/SportMate.Domain.csproj SportMate.Domain/
COPY SportMate.Application/SportMate.Application.csproj SportMate.Application/
COPY SportMate.Infrastructure/SportMate.Infrastructure.csproj SportMate.Infrastructure/
COPY SportMate.API/SportMate.API.csproj SportMate.API/
RUN dotnet restore SportMate.API/SportMate.API.csproj

COPY . .
RUN dotnet publish SportMate.API/SportMate.API.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

# ---------- Runtime ----------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

# Uploaded product images are written here; mount a volume to keep them.
RUN mkdir -p /app/wwwroot/uploads && chown -R $APP_UID /app/wwwroot
USER $APP_UID

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "SportMate.API.dll"]
