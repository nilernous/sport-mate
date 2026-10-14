using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>
/// Variant-level stock (UC-043 – UC-045). All stock changes go through conditional
/// UPDATE statements, so concurrent requests can never drive stock below zero (BR-023, BR-025, BR-075).
/// </summary>
public class InventoryService(IApplicationDbContext db, ReportSettingsAccessor reportSettings)
{
    // UC-043
    public async Task<PagedResult<InventoryItemDto>> ListAsync(InventoryQuery q, CancellationToken ct)
    {
        var query = db.ProductVariants.AsNoTracking();
        if (q.ProductId is not null) query = query.Where(v => v.ProductId == q.ProductId);
        if (q.VariantId is not null) query = query.Where(v => v.Id == q.VariantId);
        if (q.MaxStock is not null) query = query.Where(v => v.StockQuantity <= q.MaxStock);
        if (!string.IsNullOrWhiteSpace(q.Keyword))
        {
            var k = q.Keyword.Trim();
            query = query.Where(v => v.Sku.Contains(k) || v.Product.Name.Contains(k));
        }

        return await query.OrderBy(v => v.StockQuantity).ThenBy(v => v.Product.Name).ThenBy(v => v.Id)
            .Select(v => new InventoryItemDto(v.Id, v.ProductId, v.Product.Name, v.Sku, v.Size, v.Color, v.Price, v.StockQuantity, v.IsActive))
            .ToPagedResultAsync(q, ct);
    }

    // UC-044
    public async Task<InventoryItemDto> AdjustAsync(int actorId, int variantId, AdjustStockRequest r, CancellationToken ct)
    {
        if (r.QuantityChange == 0) throw AppException.BadRequest("quantityChange must not be zero.", "quantityChange");
        if (!await db.ProductVariants.AnyAsync(v => v.Id == variantId, ct)) throw AppException.NotFound("Variant");

        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var after = await ChangeStockAsync(variantId, r.QuantityChange, ct)
                    ?? throw AppException.Conflict("Stock cannot become negative.");
        db.StockMovements.Add(new StockMovement
        {
            VariantId = variantId, QuantityChange = r.QuantityChange, QuantityAfter = after,
            Type = StockMovementType.ManualAdjustment, Reason = r.Reason.Trim(), ActorUserId = actorId,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        return await db.ProductVariants.AsNoTracking().Where(v => v.Id == variantId)
            .Select(v => new InventoryItemDto(v.Id, v.ProductId, v.Product.Name, v.Sku, v.Size, v.Color, v.Price, v.StockQuantity, v.IsActive))
            .SingleAsync(ct);
    }

    // UC-045
    public async Task<PagedResult<StockMovementDto>> ListMovementsAsync(StockMovementQuery q, CancellationToken ct)
    {
        var (fromUtc, toUtc) = reportSettings.ToUtcRange(q.From, q.To, requireRange: false);
        var query = db.StockMovements.AsNoTracking();
        if (q.VariantId is not null) query = query.Where(m => m.VariantId == q.VariantId);
        if (q.ProductId is not null) query = query.Where(m => m.Variant.ProductId == q.ProductId);
        if (q.Type is not null) query = query.Where(m => m.Type == q.Type);
        if (fromUtc is not null) query = query.Where(m => m.CreatedAt >= fromUtc);
        if (toUtc is not null) query = query.Where(m => m.CreatedAt < toUtc);

        return await query.OrderByDescending(m => m.CreatedAt).ThenByDescending(m => m.Id)
            .Select(m => new StockMovementDto(m.Id, m.VariantId, m.Variant.Sku, m.Variant.Product.Name, m.QuantityChange,
                m.QuantityAfter, m.Type, m.Reason, m.OrderId, m.ActorUser != null ? m.ActorUser.FullName : null, m.CreatedAt))
            .ToPagedResultAsync(q, ct);
    }

    /// <summary>
    /// Atomically applies <paramref name="change"/> only if the result stays non-negative.
    /// Returns the new quantity, or null when there is not enough stock. Call inside a transaction.
    /// </summary>
    public async Task<int?> ChangeStockAsync(int variantId, int change, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var affected = await db.ProductVariants
            .Where(v => v.Id == variantId && v.StockQuantity + change >= 0)
            .ExecuteUpdateAsync(s => s
                .SetProperty(v => v.StockQuantity, v => v.StockQuantity + change)
                .SetProperty(v => v.UpdatedAt, now), ct);
        if (affected == 0) return null;

        return await db.ProductVariants.Where(v => v.Id == variantId).Select(v => v.StockQuantity).SingleAsync(ct);
    }
}
