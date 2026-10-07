using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Every query is scoped to the current user so addresses never leak across accounts (BR-012).</summary>
public class AddressService(IApplicationDbContext db)
{
    public const int MaxAddressesPerUser = 10;

    // UC-010
    public async Task<IReadOnlyList<AddressDto>> ListAsync(int userId, CancellationToken ct) =>
        await db.UserAddresses.Where(a => a.UserId == userId)
            .OrderByDescending(a => a.IsDefault).ThenByDescending(a => a.UpdatedAt)
            .Select(a => a.ToDto())
            .ToListAsync(ct);

    // UC-009
    public async Task<AddressDto> CreateAsync(int userId, AddressRequest request, CancellationToken ct)
    {
        var count = await db.UserAddresses.CountAsync(a => a.UserId == userId, ct);
        if (count >= MaxAddressesPerUser)
            throw AppException.BadRequest($"You can save up to {MaxAddressesPerUser} addresses.");

        var now = DateTime.UtcNow;
        var address = new UserAddress { UserId = userId, CreatedAt = now };
        Apply(address, request, now);
        // The first address becomes the default automatically.
        address.IsDefault = request.IsDefault || count == 0;
        if (address.IsDefault) await ClearDefaultAsync(userId, ct);

        db.UserAddresses.Add(address);
        await db.SaveChangesAsync(ct);
        return address.ToDto();
    }

    private async Task ClearDefaultAsync(int userId, CancellationToken ct) =>
        await db.UserAddresses.Where(a => a.UserId == userId && a.IsDefault)
            .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false), ct);

    private static void Apply(UserAddress address, AddressRequest r, DateTime now)
    {
        address.RecipientName = r.RecipientName.Trim();
        address.PhoneNumber = r.PhoneNumber.Trim();
        address.AddressLine = r.AddressLine.Trim();
        address.Ward = r.Ward.Trim();
        address.District = r.District.Trim();
        address.City = r.City.Trim();
        address.UpdatedAt = now;
    }
}
