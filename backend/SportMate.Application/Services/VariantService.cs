using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Product variants (UC-030).</summary>
public class VariantService(IApplicationDbContext db)
{
    // UC-030
    public async Task<VariantDto> CreateVariantAsync(int actorId, int productId, CreateVariantRequest r, CancellationToken ct)
    {
        await EnsureProductAsync(productId, ct);
        var sku = TextNormalizer.Key(r.Sku);
        await EnsureUniqueSkuAsync(sku, ct);
        await EnsureUniqueOptionAsync(productId, r.Size, r.Color, ct);

        var now = DateTime.UtcNow;
        var variant = new ProductVariant
        {
            ProductId = productId, Sku = sku, Size = r.Size.Trim(), Color = r.Color.Trim(), Price = r.Price,
            StockQuantity = r.InitialStock, IsActive = r.IsActive, CreatedAt = now, UpdatedAt = now,
        };
        db.ProductVariants.Add(variant);
        await db.SaveChangesAsync(ct);

        if (r.InitialStock > 0)
        {
            db.StockMovements.Add(new StockMovement
            {
                VariantId = variant.Id, QuantityChange = r.InitialStock, QuantityAfter = r.InitialStock,
                Type = StockMovementType.ManualAdjustment, Reason = "Initial stock", ActorUserId = actorId, CreatedAt = now,
            });
            await db.SaveChangesAsync(ct);
        }
        return variant.ToDto();
    }

    private async Task EnsureUniqueSkuAsync(string sku, CancellationToken ct)
    {
        if (await db.ProductVariants.AnyAsync(v => v.Sku == sku, ct))
            throw AppException.Conflict($"SKU '{sku}' is already in use.");
    }

    private async Task EnsureUniqueOptionAsync(int productId, string size, string color, CancellationToken ct)
    {
        size = size.Trim();
        color = color.Trim();
        if (await db.ProductVariants.AnyAsync(v => v.ProductId == productId && v.Size == size && v.Color == color, ct))
            throw AppException.Conflict($"This product already has a {color} / {size} variant.");
    }

    private async Task EnsureProductAsync(int productId, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId, ct)) throw AppException.NotFound("Product");
    }
}
