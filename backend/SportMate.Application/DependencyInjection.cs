using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SportMate.Application.Common;
using SportMate.Application.Services;

namespace SportMate.Application;

public static class DependencyInjection
{
    /// <summary>Registers the use-case services and their settings.</summary>
    public static IServiceCollection AddApplication(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<AuthService>();
        services.AddScoped<AddressService>();
        services.AddScoped<CategoryBrandService>();
        services.AddScoped<ProductService>();
        services.AddScoped<VariantService>();
        return services;
    }
}
