using System.Security.Claims;
using SportMate.Application.Common;
using SportMate.Domain.Enums;

namespace SportMate.API.Common;

public static class ClaimsPrincipalExtensions
{
    /// <summary>Current user id taken from the validated JWT, never from client input (BR-006).</summary>
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(AuthClaims.UserId);
        return int.TryParse(value, out var id) ? id : throw AppException.Unauthorized("Missing user identity.");
    }

    public static int? FindUserId(this ClaimsPrincipal user) =>
        int.TryParse(user.FindFirstValue(AuthClaims.UserId), out var id) ? id : null;

    public static bool IsStaffOrAdmin(this ClaimsPrincipal user) =>
        user.IsInRole(nameof(UserRole.Staff)) || user.IsInRole(nameof(UserRole.Admin));
}

public static class Roles
{
    public const string Admin = nameof(UserRole.Admin);
    public const string Customer = nameof(UserRole.Customer);

    /// <summary>The shared /admin/* operational endpoints accept both Staff and Admin.</summary>
    public const string StaffOrAdmin = nameof(UserRole.Staff) + "," + nameof(UserRole.Admin);
}
