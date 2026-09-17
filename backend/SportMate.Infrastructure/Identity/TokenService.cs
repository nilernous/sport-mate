using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Domain.Entities;

namespace SportMate.Infrastructure.Identity;

public class TokenService(IOptions<JwtSettings> options) : ITokenService
{
    private readonly JwtSettings _settings = options.Value;

    public (string Token, DateTime ExpiresAt) CreateAccessToken(User user)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(_settings.ExpiresMinutes);
        var claims = new List<Claim>
        {
            new(AuthClaims.UserId, user.Id.ToString()),
            new(AuthClaims.Name, user.FullName),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(AuthClaims.Role, user.Role.ToString()),
            new(AuthClaims.TokenVersion, user.TokenVersion.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Key));
        var token = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: _settings.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }
}
