using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SportMate.Application.Interfaces;
using SportMate.Infrastructure.Identity;
using SportMate.Infrastructure.Persistence;
using SportMate.Infrastructure.Storage;

namespace SportMate.Infrastructure;

public static class DependencyInjection
{
    /// <summary>Registers EF Core/SQL Server, JWT issuing, password hashing and file storage.</summary>
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration, string webRootPath)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());
        services.AddScoped<DataSeeder>();

        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.Section));
        services.AddSingleton<ITokenService, TokenService>();
        services.AddSingleton<IPasswordHasher, PasswordHasher>();

        services.Configure<FileStorageOptions>(o => o.RootPath = webRootPath);
        services.AddSingleton<IFileStorage, LocalFileStorage>();
        return services;
    }
}
