using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Shopping cart (UC-046 – UC-050). Every operation is scoped to the caller's own cart (BR-029).</summary>
public class CartService(IApplicationDbContext db)
{
    public const int MaxQuantityPerItem = 99;

    // UC-046
    public async Task<CartDto> GetAsync(int userId, CancellationToken ct)
    {
        var items = await GetItemsAsync(userId, ct);
        return new CartDto(items, items.Sum(i => i.Quantity), items.Where(i => i.IsAvailable).Sum(i => i.LineTotal));
    }

    /// <summary>Cart lines priced from the current catalog, never from stored prices (BR-031).</summary>
    public async Task<List<CartItemDto>> GetItemsAsync(int userId, CancellationToken ct) =>
        await db.CartItems.AsNoTracking()
            .Where(i => i.Cart.UserId == userId)
            .OrderBy(i => i.CreatedAt).ThenBy(i => i.Id)
            .Select(i => new CartItemDto(
                i.Id, i.VariantId, i.Variant.ProductId, i.Variant.Product.Name, i.Variant.Sku, i.Variant.Size, i.Variant.Color,
                i.Variant.Product.Images.OrderByDescending(img => img.IsPrimary).ThenBy(img => img.DisplayOrder).Select(img => img.Url).FirstOrDefault(),
                i.Variant.Price, i.Quantity, i.Variant.Price * i.Quantity, i.Variant.StockQuantity,
                i.Variant.IsActive && i.Variant.Product.IsActive && i.Variant.Product.Category.IsActive && i.Variant.Product.Brand.IsActive
                && i.Variant.StockQuantity >= i.Quantity))
            .ToListAsync(ct);

    // UC-047: adding an existing variant increases its quantity.
    public async Task<CartDto> AddItemAsync(int userId, AddCartItemRequest r, CancellationToken ct)
    {
        var variant = await GetPurchasableVariantAsync(r.VariantId, ct);
        var cart = await GetOrCreateCartAsync(userId, ct);
        var item = cart.Items.SingleOrDefault(i => i.VariantId == r.VariantId);
        var newQuantity = (item?.Quantity ?? 0) + r.Quantity;

        EnsureQuantity(newQuantity, variant);
        if (item is null)
            cart.Items.Add(new CartItem { VariantId = r.VariantId, Quantity = newQuantity, CreatedAt = DateTime.UtcNow });
        else
            item.Quantity = newQuantity;

        cart.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetAsync(userId, ct);
    }

    // UC-048
    public async Task<CartDto> UpdateItemAsync(int userId, int itemId, UpdateCartItemRequest r, CancellationToken ct)
    {
        var item = await FindOwnedItemAsync(userId, itemId, ct);
        var variant = await GetPurchasableVariantAsync(item.VariantId, ct);
        EnsureQuantity(r.Quantity, variant);
        item.Quantity = r.Quantity;
        await db.SaveChangesAsync(ct);
        return await GetAsync(userId, ct);
    }

    // UC-049
    public async Task<CartDto> RemoveItemAsync(int userId, int itemId, CancellationToken ct)
    {
        var item = await FindOwnedItemAsync(userId, itemId, ct);
        db.CartItems.Remove(item);
        await db.SaveChangesAsync(ct);
        return await GetAsync(userId, ct);
    }

    // UC-050: clearing an empty cart is a no-op.
    public async Task ClearAsync(int userId, CancellationToken ct) =>
        await db.CartItems.Where(i => i.Cart.UserId == userId).ExecuteDeleteAsync(ct);

    private async Task<Cart> GetOrCreateCartAsync(int userId, CancellationToken ct)
    {
        var cart = await db.Carts.Include(c => c.Items).SingleOrDefaultAsync(c => c.UserId == userId, ct);
        if (cart is not null) return cart;

        cart = new Cart { UserId = userId, UpdatedAt = DateTime.UtcNow };
        db.Carts.Add(cart);
        return cart;
    }

    private async Task<CartItem> FindOwnedItemAsync(int userId, int itemId, CancellationToken ct) =>
        await db.CartItems.SingleOrDefaultAsync(i => i.Id == itemId && i.Cart.UserId == userId, ct)
        ?? throw AppException.NotFound("Cart item");

    // BR-030: only active variants of visible products can be in a cart.
    private async Task<ProductVariant> GetPurchasableVariantAsync(int variantId, CancellationToken ct) =>
        await db.ProductVariants.AsNoTracking()
            .SingleOrDefaultAsync(v => v.Id == variantId && v.IsActive && v.Product.IsActive
                                       && v.Product.Category.IsActive && v.Product.Brand.IsActive, ct)
        ?? throw AppException.BadRequest("This product option is not available for purchase.", "variantId");

    private static void EnsureQuantity(int quantity, ProductVariant variant)
    {
        if (quantity > MaxQuantityPerItem)
            throw AppException.BadRequest($"You can buy at most {MaxQuantityPerItem} of one item.", "quantity");
        if (quantity > variant.StockQuantity)
            throw AppException.Conflict(variant.StockQuantity == 0
                ? "This item is out of stock."
                : $"Only {variant.StockQuantity} left in stock.");
    }
}
