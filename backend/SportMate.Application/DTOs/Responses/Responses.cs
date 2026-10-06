using SportMate.Application.Common;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.DTOs.Responses;

// ---------- Auth & users ----------

public record UserDto(int Id, string FullName, string Email, string? PhoneNumber, UserRole Role);

public record AuthResponse(string AccessToken, DateTime ExpiresAt, UserDto User);

public record MessageResponse(string Message);
