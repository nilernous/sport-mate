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

/// <summary>Stores uploaded files and returns the URL clients use to load them.</summary>
public interface IFileStorage
{
    /// <summary>Saves <paramref name="content"/> under <paramref name="folder"/> and returns its public URL.</summary>
    Task<string> SaveAsync(Stream content, string folder, string fileName, CancellationToken ct);

    /// <summary>Deletes a file previously returned by <see cref="SaveAsync"/>. URLs it does not own are ignored.</summary>
    Task DeleteAsync(string url, CancellationToken ct);
}
