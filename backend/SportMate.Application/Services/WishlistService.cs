using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Wishlist (UC-073 – UC-075), always scoped to the current customer (BR-066).</summary>
public class WishlistService(IApplicationDbContext db)
{
    // UC-073
    public async Task<IReadOnlyList<WishlistItemDto>> ListAsync(int userId, CancellationToken ct) =>
        await db.WishlistItems.AsNoTracking().Where(w => w.UserId == userId)
            .OrderByDescending(w => w.CreatedAt)
            .Select(w => new WishlistItemDto(
                w.ProductId, w.Product.Name,
                w.Product.Variants.Where(v => v.IsActive).Min(v => (decimal?)v.Price) ?? w.Product.BasePrice,
                w.Product.Images.OrderByDescending(i => i.IsPrimary).ThenBy(i => i.DisplayOrder).Select(i => i.Url).FirstOrDefault(),
                w.Product.Variants.Any(v => v.IsActive && v.StockQuantity > 0),
                w.Product.IsActive && w.Product.Category.IsActive && w.Product.Brand.IsActive,
                w.CreatedAt))
            .ToListAsync(ct);

    // UC-074: adding a product twice is an idempotent no-op.
    public async Task<bool> AddAsync(int userId, int productId, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId && p.IsActive, ct)) throw AppException.NotFound("Product");
        if (await db.WishlistItems.AnyAsync(w => w.UserId == userId && w.ProductId == productId, ct)) return false;

        db.WishlistItems.Add(new WishlistItem { UserId = userId, ProductId = productId, CreatedAt = DateTime.UtcNow });
        await db.SaveChangesAsync(ct);
        return true;
    }

    // UC-075: removing a missing entry is a no-op.
    public async Task RemoveAsync(int userId, int productId, CancellationToken ct) =>
        await db.WishlistItems.Where(w => w.UserId == userId && w.ProductId == productId).ExecuteDeleteAsync(ct);
}
