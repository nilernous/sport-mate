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
