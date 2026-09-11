namespace SportMate.Application.Common;

public static class TextNormalizer
{
    /// <summary>Normalization used for case-insensitive unique keys: email, SKU, coupon code.</summary>
    public static string Key(string value) => value.Trim().ToUpperInvariant();

    public static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
