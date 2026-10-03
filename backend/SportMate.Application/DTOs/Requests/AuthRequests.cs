using System.ComponentModel.DataAnnotations;
using SportMate.Application.Common;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.DTOs.Requests;

public static class PasswordPolicy
{
    // At least 8 characters with one letter and one digit.
    public const string Pattern = @"^(?=.*[A-Za-z])(?=.*\d).{8,100}$";
    public const string Message = "Password must be 8-100 characters and contain at least one letter and one digit.";
}

public class RegisterRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string FullName { get; init; } = string.Empty;

    [Required, EmailAddress, StringLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required, RegularExpression(PasswordPolicy.Pattern, ErrorMessage = PasswordPolicy.Message)]
    public string Password { get; init; } = string.Empty;

    [Phone, StringLength(20)]
    public string? PhoneNumber { get; init; }
}

public class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}

public class ForgotPasswordRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;
}

public class ResetPasswordRequest
{
    [Required]
    public string Token { get; init; } = string.Empty;

    [Required, RegularExpression(PasswordPolicy.Pattern, ErrorMessage = PasswordPolicy.Message)]
    public string NewPassword { get; init; } = string.Empty;
}

public class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; init; } = string.Empty;

    [Required, RegularExpression(PasswordPolicy.Pattern, ErrorMessage = PasswordPolicy.Message)]
    public string NewPassword { get; init; } = string.Empty;
}

/// <summary>Only these fields are editable by the user themself (BR-011).</summary>
public class UpdateProfileRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string FullName { get; init; } = string.Empty;

    [Phone, StringLength(20)]
    public string? PhoneNumber { get; init; }
}

public class AddressRequest
{
    [Required, StringLength(100)]
    public string RecipientName { get; init; } = string.Empty;

    [Required, Phone, StringLength(20)]
    public string PhoneNumber { get; init; } = string.Empty;

    [Required, StringLength(255)]
    public string AddressLine { get; init; } = string.Empty;

    [Required, StringLength(100)]
    public string Ward { get; init; } = string.Empty;

    [Required, StringLength(100)]
    public string District { get; init; } = string.Empty;

    [Required, StringLength(100)]
    public string City { get; init; } = string.Empty;

    public bool IsDefault { get; init; }
}

public class AdminCreateUserRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string FullName { get; init; } = string.Empty;

    [Required, EmailAddress, StringLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required, RegularExpression(PasswordPolicy.Pattern, ErrorMessage = PasswordPolicy.Message)]
    public string Password { get; init; } = string.Empty;

    [Phone, StringLength(20)]
    public string? PhoneNumber { get; init; }

    [Required, EnumDataType(typeof(UserRole))]
    public UserRole Role { get; init; } = UserRole.Customer;
}

public class AdminUpdateUserRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string FullName { get; init; } = string.Empty;

    [Required, EmailAddress, StringLength(256)]
    public string Email { get; init; } = string.Empty;

    [Phone, StringLength(20)]
    public string? PhoneNumber { get; init; }
}

public class UpdateUserStatusRequest
{
    [Required]
    public bool? IsActive { get; init; }
}

public class UpdateUserRoleRequest
{
    [Required, EnumDataType(typeof(UserRole))]
    public UserRole? Role { get; init; }
}

public class UserQuery : PageQuery
{
    [StringLength(100)]
    public string? Keyword { get; init; }

    public UserRole? Role { get; init; }
    public bool? IsActive { get; init; }
}
