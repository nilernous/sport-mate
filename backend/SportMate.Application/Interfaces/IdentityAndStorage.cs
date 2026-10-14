using SportMate.Domain.Entities;

namespace SportMate.Application.Interfaces;

/// <summary>Issues access tokens for a signed-in user.</summary>
public interface ITokenService
{
    (string Token, DateTime ExpiresAt) CreateAccessToken(User user);
}

/// <summary>Secure one-way password hashing (BR-009).</summary>
public interface IPasswordHasher
{
    string Hash(User user, string password);

    bool Verify(User user, string hashedPassword, string providedPassword);
}

