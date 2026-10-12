using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Admin-only user management (UC-013 – UC-017).</summary>
public class UserAdminService(IApplicationDbContext db, IPasswordHasher hasher)
{
    // UC-013
    public async Task<AdminUserDto> CreateAsync(AdminCreateUserRequest request, CancellationToken ct)
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
            Role = request.Role,
            CreatedAt = now,
            UpdatedAt = now,
        };
        user.PasswordHash = hasher.Hash(user, request.Password);
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return user.ToAdminDto();
    }

    // UC-014
    public async Task<PagedResult<AdminUserDto>> ListAsync(UserQuery q, CancellationToken ct)
    {
        var query = db.Users.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(q.Keyword))
        {
            var k = q.Keyword.Trim();
            query = query.Where(u => u.FullName.Contains(k) || u.Email.Contains(k) || (u.PhoneNumber != null && u.PhoneNumber.Contains(k)));
        }
        if (q.Role is not null) query = query.Where(u => u.Role == q.Role);
        if (q.IsActive is not null) query = query.Where(u => u.IsActive == q.IsActive);

        return await query.OrderByDescending(u => u.CreatedAt)
            .Select(u => new AdminUserDto(u.Id, u.FullName, u.Email, u.PhoneNumber, u.Role, u.IsActive, u.CreatedAt, u.UpdatedAt))
            .ToPagedResultAsync(q, ct);
    }

    // UC-014
    public async Task<AdminUserDetailDto> GetAsync(int id, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().Include(u => u.Addresses)
            .SingleOrDefaultAsync(u => u.Id == id, ct) ?? throw AppException.NotFound("User");
        var orderCount = await db.Orders.CountAsync(o => o.UserId == id, ct);
        return new AdminUserDetailDto(user.Id, user.FullName, user.Email, user.PhoneNumber, user.Role, user.IsActive,
            user.CreatedAt, user.UpdatedAt, orderCount, user.Addresses.Select(a => a.ToDto()).ToList());
    }

    // UC-015
    public async Task<AdminUserDto> UpdateAsync(int id, AdminUpdateUserRequest request, CancellationToken ct)
    {
        var user = await FindAsync(id, ct);
        var normalizedEmail = TextNormalizer.Key(request.Email);
        if (normalizedEmail != user.NormalizedEmail &&
            await db.Users.AnyAsync(u => u.NormalizedEmail == normalizedEmail && u.Id != id, ct))
            throw AppException.Conflict("An account with this email already exists.");

        user.FullName = request.FullName.Trim();
        user.Email = request.Email.Trim();
        user.NormalizedEmail = normalizedEmail;
        user.PhoneNumber = TextNormalizer.Clean(request.PhoneNumber);
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return user.ToAdminDto();
    }

    // UC-016: disabling revokes the user's tokens; history is kept (BR-007).
    public async Task<AdminUserDto> SetStatusAsync(int actorId, int id, bool isActive, CancellationToken ct)
    {
        var user = await FindAsync(id, ct);
        if (user.IsActive == isActive) return user.ToAdminDto();

        if (!isActive)
        {
            if (id == actorId) throw AppException.Conflict("You cannot disable your own account.");
            await EnsureNotLastActiveAdminAsync(user, ct);
            user.TokenVersion++;
        }

        user.IsActive = isActive;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return user.ToAdminDto();
    }

    // UC-017
    public async Task<AdminUserDto> SetRoleAsync(int actorId, int id, UserRole role, CancellationToken ct)
    {
        var user = await FindAsync(id, ct);
        if (user.Role == role) return user.ToAdminDto();
        if (id == actorId) throw AppException.Conflict("You cannot change your own role.");
        if (user.Role == UserRole.Admin) await EnsureNotLastActiveAdminAsync(user, ct);

        user.Role = role;
        // Old tokens still carry the previous role claim, so revoke them.
        user.TokenVersion++;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return user.ToAdminDto();
    }

    private async Task EnsureNotLastActiveAdminAsync(User user, CancellationToken ct)
    {
        if (user.Role != UserRole.Admin || !user.IsActive) return;
        var otherAdmins = await db.Users.CountAsync(u => u.Role == UserRole.Admin && u.IsActive && u.Id != user.Id, ct);
        if (otherAdmins == 0) throw AppException.Conflict("The last active administrator cannot be disabled or demoted.");
    }

    private async Task<User> FindAsync(int id, CancellationToken ct) =>
        await db.Users.SingleOrDefaultAsync(u => u.Id == id, ct) ?? throw AppException.NotFound("User");
}
