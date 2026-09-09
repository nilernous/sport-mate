using SportMate.Domain.Enums;

namespace SportMate.Domain.Entities;

public class User
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    /// <summary>Upper-cased, trimmed email used for uniqueness checks (BR-008).</summary>
    public string NormalizedEmail { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public UserRole Role { get; set; } = UserRole.Customer;
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Embedded in every JWT. Incrementing it revokes all previously issued tokens
    /// (sign out, password change, account disable, role change).
    /// </summary>
    public int TokenVersion { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<UserAddress> Addresses { get; set; } = [];
}

public class PasswordResetToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    /// <summary>SHA-256 hash of the token; the raw token is never stored.</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UserAddress
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public string RecipientName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string AddressLine { get; set; } = string.Empty;
    public string Ward { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
