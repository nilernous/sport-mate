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
        services.Configure<ShippingSettings>(configuration.GetSection(ShippingSettings.Section));
        services.Configure<BankTransferSettings>(configuration.GetSection(BankTransferSettings.Section));
        services.Configure<ReportSettings>(configuration.GetSection(ReportSettings.Section));

        services.AddSingleton<ReportSettingsAccessor>();
        services.AddScoped<AuthService>();
        services.AddScoped<AddressService>();
        services.AddScoped<UserAdminService>();
        services.AddScoped<CategoryBrandService>();
        services.AddScoped<ProductService>();
        services.AddScoped<VariantImageService>();
        services.AddScoped<InventoryService>();
        services.AddScoped<CartService>();
        services.AddScoped<CouponService>();
        services.AddScoped<PaymentService>();
        services.AddScoped<OrderService>();
        services.AddScoped<WishlistService>();
        return services;
    }
}
