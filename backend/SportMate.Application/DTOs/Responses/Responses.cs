using SportMate.Application.Common;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.DTOs.Responses;

// ---------- Auth & users ----------

public record UserDto(int Id, string FullName, string Email, string? PhoneNumber, UserRole Role);

public record AuthResponse(string AccessToken, DateTime ExpiresAt, UserDto User);

public record MessageResponse(string Message);

public record AddressDto(
    int Id, string RecipientName, string PhoneNumber, string AddressLine, string Ward, string District,
    string City, bool IsDefault);

// ---------- Catalog ----------

public record CategoryDto(int Id, string Name, string? Description, bool IsActive, int ProductCount);

public record BrandDto(int Id, string Name, string? Description, string? LogoUrl, bool IsActive, int ProductCount);

/// <summary>Result of a delete request that may fall back to deactivation (BR-020).</summary>
public record DeleteResultDto(string Action, string Message)
{
    public static DeleteResultDto Deleted(string resource) => new("Deleted", $"{resource} was deleted.");

    public static DeleteResultDto Deactivated(string resource, string reason) =>
        new("Deactivated", $"{resource} is referenced by {reason}, so it was deactivated instead of deleted.");
}

public record ProductSummaryDto(
    int Id, string Name, string CategoryName, string BrandName, decimal Price, string? ImageUrl,
    double AverageRating, int ReviewCount, bool InStock, bool IsActive);

public record VariantDto(
    int Id, int ProductId, string Sku, string Size, string Color, decimal Price, int StockQuantity, bool InStock,
    bool IsActive);

public record ImageDto(int Id, int ProductId, string Url, string? AltText, int DisplayOrder, bool IsPrimary);

public record ProductDetailDto(
    int Id, string Name, string? Description, int CategoryId, string CategoryName, int BrandId, string BrandName,
    decimal BasePrice, decimal Price, bool IsActive, double AverageRating, int ReviewCount,
    IReadOnlyList<ImageDto> Images, IReadOnlyList<VariantDto> Variants, DateTime CreatedAt, DateTime UpdatedAt);

public record FilterOptionsDto(
    IReadOnlyList<CategoryDto> Categories, IReadOnlyList<BrandDto> Brands, IReadOnlyList<string> Sizes,
    IReadOnlyList<string> Colors, decimal MinPrice, decimal MaxPrice);
