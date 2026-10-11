using Microsoft.EntityFrameworkCore;
using SportMate.Application.Interfaces;

namespace SportMate.Application.Services;

/// <summary>
/// Variant-level stock. All stock changes go through conditional UPDATE statements,
/// so concurrent requests can never drive stock below zero (BR-023, BR-025, BR-075).
/// </summary>
public class InventoryService(IApplicationDbContext db)
{
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
