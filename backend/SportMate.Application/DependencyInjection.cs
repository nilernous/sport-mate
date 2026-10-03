using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SportMate.Application.Common;

namespace SportMate.Application;

public static class DependencyInjection
{
    /// <summary>Registers the use-case services and their settings.</summary>
    public static IServiceCollection AddApplication(this IServiceCollection services, IConfiguration configuration)
    {
        return services;
    }
}
