namespace SportMate.Infrastructure.Identity;

public class JwtSettings
{
    public const string Section = "Jwt";

    /// <summary>
    /// Signing key (32+ bytes). The development key lives in appsettings.Development.json;
    /// other environments must supply their own, e.g. the Jwt__Key environment variable (BR-077).
    /// </summary>
    public string Key { get; set; } = string.Empty;

    public string Issuer { get; set; } = "SportMate.API";
    public string Audience { get; set; } = "SportMate.Mobile";
    public int ExpiresMinutes { get; set; } = 60 * 24 * 7;
}
