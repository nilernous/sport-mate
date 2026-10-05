using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

public class AuthService(
    IApplicationDbContext db,
    ITokenService tokens,
    IPasswordHasher hasher,
    ILogger<AuthService> logger)
{
    private static readonly TimeSpan ResetTokenLifetime = TimeSpan.FromMinutes(30);

    // UC-001
    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct)
    {
        var normalizedEmail = TextNormalizer.Key(request.Email);
        if (await db.Users.AnyAsync(u => u.NormalizedEmail == normalizedEmail, ct))
            throw AppException.Conflict("An account with this email already exists.");

        var now = DateTime.UtcNow;
        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = request.Email.Trim(),
            NormalizedEmail = normalizedEmail,
            PhoneNumber = TextNormalizer.Clean(request.PhoneNumber),
            Role = UserRole.Customer,
            CreatedAt = now,
            UpdatedAt = now,
        };
        user.PasswordHash = hasher.Hash(user, request.Password);
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return CreateAuthResponse(user);
    }

    // UC-002
    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct)
    {
        var normalizedEmail = TextNormalizer.Key(request.Email);
        var user = await db.Users.SingleOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail, ct);
        if (user is null || !hasher.Verify(user, user.PasswordHash, request.Password))
            throw AppException.Unauthorized("Email or password is incorrect.");

        if (!user.IsActive)
            throw AppException.Forbidden("This account has been disabled.");

        return CreateAuthResponse(user);
    }

    // UC-003: bumping the token version revokes every token issued to this user.
    public async Task LogoutAsync(int userId, CancellationToken ct)
    {
        await db.Users.Where(u => u.Id == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.TokenVersion, u => u.TokenVersion + 1), ct);
    }

    // UC-004: always succeeds so the response never reveals whether the email exists (BR-010).
    public async Task ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken ct)
    {
        var normalizedEmail = TextNormalizer.Key(request.Email);
        var user = await db.Users.SingleOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail && u.IsActive, ct);
        if (user is null) return;

        var now = DateTime.UtcNow;
        await db.PasswordResetTokens
            .Where(t => t.UserId == user.Id && t.UsedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.UsedAt, now), ct);

        var rawToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        db.PasswordResetTokens.Add(new PasswordResetToken
        {
            UserId = user.Id,
            TokenHash = Hash(rawToken),
            ExpiresAt = now.Add(ResetTokenLifetime),
            CreatedAt = now,
        });
        await db.SaveChangesAsync(ct);

        // No mail service is in scope: the token is written to the server log, standing in for the reset email.
        logger.LogInformation("Password reset token for user {UserId}: {Token} (expires {ExpiresAt:u})",
            user.Id, rawToken, now.Add(ResetTokenLifetime));
    }

    // UC-005
    public async Task ResetPasswordAsync(ResetPasswordRequest request, CancellationToken ct)
    {
        var tokenHash = Hash(request.Token.Trim());
        var token = await db.PasswordResetTokens.Include(t => t.User)
            .SingleOrDefaultAsync(t => t.TokenHash == tokenHash, ct);

        if (token is null || token.UsedAt is not null || token.ExpiresAt < DateTime.UtcNow || !token.User.IsActive)
            throw AppException.BadRequest("The reset token is invalid or has expired.", "token");

        token.UsedAt = DateTime.UtcNow;
        SetPassword(token.User, request.NewPassword);
        await db.SaveChangesAsync(ct);
    }

    // UC-006: returns a fresh token because all older ones are revoked.
    public async Task<AuthResponse> ChangePasswordAsync(int userId, ChangePasswordRequest request, CancellationToken ct)
    {
        var user = await GetActiveUserAsync(userId, ct);
        if (!hasher.Verify(user, user.PasswordHash, request.CurrentPassword))
            throw AppException.BadRequest("Current password is incorrect.", "currentPassword");
        if (request.CurrentPassword == request.NewPassword)
            throw AppException.BadRequest("New password must be different from the current password.", "newPassword");

        SetPassword(user, request.NewPassword);
        await db.SaveChangesAsync(ct);
        return CreateAuthResponse(user);
    }

    // UC-007
    public async Task<UserDto> GetProfileAsync(int userId, CancellationToken ct) =>
        (await GetActiveUserAsync(userId, ct)).ToDto();

    // UC-008
    public async Task<UserDto> UpdateProfileAsync(int userId, UpdateProfileRequest request, CancellationToken ct)
    {
        var user = await GetActiveUserAsync(userId, ct);
        user.FullName = request.FullName.Trim();
        user.PhoneNumber = TextNormalizer.Clean(request.PhoneNumber);
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return user.ToDto();
    }

    private void SetPassword(User user, string password)
    {
        user.PasswordHash = hasher.Hash(user, password);
        user.TokenVersion++;
        user.UpdatedAt = DateTime.UtcNow;
    }

    private async Task<User> GetActiveUserAsync(int userId, CancellationToken ct) =>
        await db.Users.SingleOrDefaultAsync(u => u.Id == userId && u.IsActive, ct)
        ?? throw AppException.Unauthorized("Account is not available.");

    private AuthResponse CreateAuthResponse(User user)
    {
        var (token, expiresAt) = tokens.CreateAccessToken(user);
        return new AuthResponse(token, expiresAt, user.ToDto());
    }

    private static string Hash(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}
