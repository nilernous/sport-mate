using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SportMate.Application.Interfaces;
using SportMate.Infrastructure.Persistence;

namespace SportMate.Infrastructure;

public static class DependencyInjection
{
    /// <summary>Registers EF Core/SQL Server, JWT issuing and password hashing.</summary>
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
        services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<ApplicationDbContext>());
        services.AddScoped<DataSeeder>();
        return services;
    }
}
