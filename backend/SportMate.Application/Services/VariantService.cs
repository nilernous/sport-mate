using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Product variants (UC-030 – UC-033).</summary>
public class VariantService(IApplicationDbContext db)
{
    // UC-031
    public async Task<IReadOnlyList<VariantDto>> ListVariantsAsync(int productId, CancellationToken ct)
    {
        await EnsureProductAsync(productId, ct);
        var variants = await db.ProductVariants.AsNoTracking().Where(v => v.ProductId == productId)
            .OrderBy(v => v.Color).ThenBy(v => v.Size).ToListAsync(ct);
        return variants.Select(v => v.ToDto()).ToList();
    }

    public async Task<VariantDto> GetVariantAsync(int id, CancellationToken ct) =>
        (await db.ProductVariants.AsNoTracking().SingleOrDefaultAsync(v => v.Id == id, ct)
         ?? throw AppException.NotFound("Variant")).ToDto();

    // UC-030
    public async Task<VariantDto> CreateVariantAsync(int actorId, int productId, CreateVariantRequest r, CancellationToken ct)
    {
        await EnsureProductAsync(productId, ct);
        var sku = TextNormalizer.Key(r.Sku);
        await EnsureUniqueSkuAsync(sku, null, ct);
        await EnsureUniqueOptionAsync(productId, r.Size, r.Color, null, ct);

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

    // UC-032
    public async Task<VariantDto> UpdateVariantAsync(int id, UpdateVariantRequest r, CancellationToken ct)
    {
        var variant = await db.ProductVariants.FindAsync([id], ct) ?? throw AppException.NotFound("Variant");
        var sku = TextNormalizer.Key(r.Sku);
        await EnsureUniqueSkuAsync(sku, id, ct);
        await EnsureUniqueOptionAsync(variant.ProductId, r.Size, r.Color, id, ct);

        variant.Sku = sku;
        variant.Size = r.Size.Trim();
        variant.Color = r.Color.Trim();
        variant.Price = r.Price;
        variant.IsActive = r.IsActive;
        variant.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return variant.ToDto();
    }

    // UC-033
    public async Task<DeleteResultDto> DeleteVariantAsync(int id, CancellationToken ct)
    {
        var variant = await db.ProductVariants.FindAsync([id], ct) ?? throw AppException.NotFound("Variant");
        if (await db.OrderItems.AnyAsync(i => i.VariantId == id, ct))
        {
            variant.IsActive = false;
            variant.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            return DeleteResultDto.Deactivated("Variant", "existing orders");
        }

        db.ProductVariants.Remove(variant);
        await db.SaveChangesAsync(ct);
        return DeleteResultDto.Deleted("Variant");
    }

    private async Task EnsureUniqueSkuAsync(string sku, int? exceptId, CancellationToken ct)
    {
        if (await db.ProductVariants.AnyAsync(v => v.Sku == sku && v.Id != exceptId, ct))
            throw AppException.Conflict($"SKU '{sku}' is already in use.");
    }

    private async Task EnsureUniqueOptionAsync(int productId, string size, string color, int? exceptId, CancellationToken ct)
    {
        size = size.Trim();
        color = color.Trim();
        if (await db.ProductVariants.AnyAsync(v => v.ProductId == productId && v.Size == size && v.Color == color && v.Id != exceptId, ct))
            throw AppException.Conflict($"This product already has a {color} / {size} variant.");
    }

    private async Task EnsureProductAsync(int productId, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId, ct)) throw AppException.NotFound("Product");
    }
}
