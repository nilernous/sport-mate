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
