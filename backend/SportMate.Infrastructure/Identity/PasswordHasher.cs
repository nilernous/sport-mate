using Microsoft.AspNetCore.Identity;
using SportMate.Application.Interfaces;
using SportMate.Domain.Entities;

namespace SportMate.Infrastructure.Identity;

/// <summary>ASP.NET Core Identity's PBKDF2 hasher behind the application interface.</summary>
public class PasswordHasher : IPasswordHasher
{
    private readonly PasswordHasher<User> _inner = new();

    public string Hash(User user, string password) => _inner.HashPassword(user, password);

    public bool Verify(User user, string hashedPassword, string providedPassword) =>
        _inner.VerifyHashedPassword(user, hashedPassword, providedPassword) != PasswordVerificationResult.Failed;
}
