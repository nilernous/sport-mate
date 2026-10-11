namespace SportMate.Application.Common;

/// <summary>JWT claim names shared by token creation (Infrastructure) and validation (API).</summary>
public static class AuthClaims
{
    public const string UserId = "sub";
    public const string Name = "name";
    public const string Role = "role";

    /// <summary>Token version: bumping the user's version revokes all of their tokens.</summary>
    public const string TokenVersion = "tv";
}
