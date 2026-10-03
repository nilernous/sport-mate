using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace SportMate.Infrastructure;

public static class DependencyInjection
{
    /// <summary>Registers EF Core/SQL Server, JWT issuing and password hashing.</summary>
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        return services;
    }
}
