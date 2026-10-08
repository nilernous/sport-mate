using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Public catalog (UC-038 – UC-042) and product administration (UC-026 – UC-029).</summary>
public class ProductService(IApplicationDbContext db)
{
    /// <summary>Flat, translatable projection used for filtering and sorting product lists.</summary>
    private sealed class ProductRow
    {
        public int Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string? Description { get; init; }
        public int CategoryId { get; init; }
        public string CategoryName { get; init; } = string.Empty;
        public int BrandId { get; init; }
        public string BrandName { get; init; } = string.Empty;
        public decimal Price { get; init; }
        public string? ImageUrl { get; init; }
        public double AverageRating { get; init; }
        public int ReviewCount { get; init; }
        public bool InStock { get; init; }
        public bool IsActive { get; init; }
        public DateTime CreatedAt { get; init; }
    }

    // UC-027
    public Task<PagedResult<ProductSummaryDto>> SearchAdminAsync(AdminProductQuery q, CancellationToken ct)
    {
        var source = db.Products.AsQueryable();
        if (q.IsActive is not null) source = source.Where(p => p.IsActive == q.IsActive);
        return SearchAsync(source, q, publicOnly: false, ct);
    }

    private async Task<PagedResult<ProductSummaryDto>> SearchAsync(IQueryable<Product> source, ProductQuery q, bool publicOnly, CancellationToken ct)
    {
        if (q.MinPrice is not null && q.MaxPrice is not null && q.MinPrice > q.MaxPrice)
            throw AppException.BadRequest("minPrice must not be greater than maxPrice.", "minPrice");

        source = source.AsNoTracking();
        if (q.CategoryId is not null) source = source.Where(p => p.CategoryId == q.CategoryId);
        if (q.BrandId is not null) source = source.Where(p => p.BrandId == q.BrandId);
        if (!string.IsNullOrWhiteSpace(q.Size))
            source = source.Where(p => p.Variants.Any(v => (!publicOnly || v.IsActive) && v.Size == q.Size.Trim()));
        if (!string.IsNullOrWhiteSpace(q.Color))
            source = source.Where(p => p.Variants.Any(v => (!publicOnly || v.IsActive) && v.Color == q.Color.Trim()));
        if (!string.IsNullOrWhiteSpace(q.Keyword))
        {
            var k = q.Keyword.Trim();
            source = source.Where(p => p.Name.Contains(k) || p.Brand.Name.Contains(k) || p.Category.Name.Contains(k)
                                       || (!publicOnly && p.Variants.Any(v => v.Sku.Contains(k))));
        }

        var rows = Project(source);
        if (q.MinPrice is not null) rows = rows.Where(r => r.Price >= q.MinPrice);
        if (q.MaxPrice is not null) rows = rows.Where(r => r.Price <= q.MaxPrice);

        var desc = string.Equals(q.SortOrder, "desc", StringComparison.OrdinalIgnoreCase);
        // Sort fields are allow-listed by the request validator (BR-021); Id keeps paging stable.
        rows = (q.SortBy?.ToLowerInvariant()) switch
        {
            "name" => desc ? rows.OrderByDescending(r => r.Name).ThenBy(r => r.Id) : rows.OrderBy(r => r.Name).ThenBy(r => r.Id),
            "price" => desc ? rows.OrderByDescending(r => r.Price).ThenBy(r => r.Id) : rows.OrderBy(r => r.Price).ThenBy(r => r.Id),
            "rating" => desc || q.SortOrder is null
                ? rows.OrderByDescending(r => r.AverageRating).ThenByDescending(r => r.ReviewCount).ThenBy(r => r.Id)
                : rows.OrderBy(r => r.AverageRating).ThenBy(r => r.Id),
            _ => desc || q.SortOrder is null
                ? rows.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id)
                : rows.OrderBy(r => r.CreatedAt).ThenBy(r => r.Id),
        };

        var page = await rows.ToPagedResultAsync(q, ct);
        return new PagedResult<ProductSummaryDto>(
            page.Items.Select(r => new ProductSummaryDto(r.Id, r.Name, r.CategoryName, r.BrandName, r.Price, r.ImageUrl,
                Math.Round(r.AverageRating, 1), r.ReviewCount, r.InStock, r.IsActive)).ToList(),
            page.Page, page.PageSize, page.TotalItems, page.TotalPages);
    }

    private static IQueryable<ProductRow> Project(IQueryable<Product> source) =>
        source.Select(p => new ProductRow
        {
            Id = p.Id,
            Name = p.Name,
            Description = p.Description,
            CategoryId = p.CategoryId,
            CategoryName = p.Category.Name,
            BrandId = p.BrandId,
            BrandName = p.Brand.Name,
            // Display price = cheapest active variant, falling back to the base price.
            Price = p.Variants.Where(v => v.IsActive).Min(v => (decimal?)v.Price) ?? p.BasePrice,
            ImageUrl = p.Images.OrderByDescending(i => i.IsPrimary).ThenBy(i => i.DisplayOrder).ThenBy(i => i.Id)
                .Select(i => i.Url).FirstOrDefault(),
            AverageRating = p.Reviews.Where(r => r.Status == ReviewStatus.Approved).Average(r => (double?)r.Rating) ?? 0,
            ReviewCount = p.Reviews.Count(r => r.Status == ReviewStatus.Approved),
            InStock = p.Variants.Any(v => v.IsActive && v.StockQuantity > 0),
            IsActive = p.IsActive,
            CreatedAt = p.CreatedAt,
        });

    // UC-027
    public async Task<ProductDetailDto> GetAdminAsync(int id, CancellationToken ct)
    {
        var product = await db.Products.AsNoTracking().AsSplitQuery()
            .Include(p => p.Category).Include(p => p.Brand)
            .Include(p => p.Images).Include(p => p.Variants)
            .SingleOrDefaultAsync(p => p.Id == id, ct) ?? throw AppException.NotFound("Product");
        return await ToDetailAsync(product, ct);
    }

    // UC-026
    public async Task<ProductDetailDto> CreateAsync(ProductRequest r, CancellationToken ct)
    {
        await EnsureReferencesAsync(r, ct);
        var now = DateTime.UtcNow;
        var product = new Product
        {
            Name = r.Name.Trim(), Description = TextNormalizer.Clean(r.Description), CategoryId = r.CategoryId,
            BrandId = r.BrandId, BasePrice = r.BasePrice, IsActive = r.IsActive, CreatedAt = now, UpdatedAt = now,
        };
        db.Products.Add(product);
        await db.SaveChangesAsync(ct);
        return await GetAdminAsync(product.Id, ct);
    }

    // UC-028: order items keep their own snapshot, so edits never rewrite history (BR-039, BR-045).
    public async Task<ProductDetailDto> UpdateAsync(int id, ProductRequest r, CancellationToken ct)
    {
        var product = await db.Products.FindAsync([id], ct) ?? throw AppException.NotFound("Product");
        await EnsureReferencesAsync(r, ct);
        product.Name = r.Name.Trim();
        product.Description = TextNormalizer.Clean(r.Description);
        product.CategoryId = r.CategoryId;
        product.BrandId = r.BrandId;
        product.BasePrice = r.BasePrice;
        product.IsActive = r.IsActive;
        product.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetAdminAsync(id, ct);
    }

    public async Task<ProductDetailDto> SetStatusAsync(int id, bool isActive, CancellationToken ct)
    {
        var product = await db.Products.FindAsync([id], ct) ?? throw AppException.NotFound("Product");
        product.IsActive = isActive;
        product.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetAdminAsync(id, ct);
    }

    // UC-029
    public async Task<DeleteResultDto> DeleteAsync(int id, CancellationToken ct)
    {
        var product = await db.Products.FindAsync([id], ct) ?? throw AppException.NotFound("Product");
        if (await db.OrderItems.AnyAsync(i => i.ProductId == id, ct))
        {
            product.IsActive = false;
            product.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            return DeleteResultDto.Deactivated("Product", "existing orders");
        }

        // Variants, images, reviews, cart and wishlist entries cascade with the product.
        db.Products.Remove(product);
        await db.SaveChangesAsync(ct);
        return DeleteResultDto.Deleted("Product");
    }

    private async Task EnsureReferencesAsync(ProductRequest r, CancellationToken ct)
    {
        if (!await db.Categories.AnyAsync(c => c.Id == r.CategoryId, ct))
            throw AppException.BadRequest("Category does not exist.", "categoryId");
        if (!await db.Brands.AnyAsync(b => b.Id == r.BrandId, ct))
            throw AppException.BadRequest("Brand does not exist.", "brandId");
    }

    private async Task<ProductDetailDto> ToDetailAsync(Product p, CancellationToken ct)
    {
        var ratings = await db.Reviews.Where(r => r.ProductId == p.Id && r.Status == ReviewStatus.Approved)
            .GroupBy(_ => 1)
            .Select(g => new { Avg = g.Average(r => (double)r.Rating), Count = g.Count() })
            .SingleOrDefaultAsync(ct);
        var activeVariants = p.Variants.Where(v => v.IsActive).ToList();
        var price = activeVariants.Count > 0 ? activeVariants.Min(v => v.Price) : p.BasePrice;

        return new ProductDetailDto(
            p.Id, p.Name, p.Description, p.CategoryId, p.Category.Name, p.BrandId, p.Brand.Name, p.BasePrice, price,
            p.IsActive, Math.Round(ratings?.Avg ?? 0, 1), ratings?.Count ?? 0,
            p.Images.OrderByDescending(i => i.IsPrimary).ThenBy(i => i.DisplayOrder).ThenBy(i => i.Id).Select(i => i.ToDto()).ToList(),
            p.Variants.OrderBy(v => v.Color).ThenBy(v => SizeRank(v.Size)).ThenBy(v => v.Size).Select(v => v.ToDto()).ToList(),
            p.CreatedAt, p.UpdatedAt);
    }

    private static readonly string[] SizeOrder = ["XXS", "XS", "S", "M", "L", "XL", "XXL", "XXXL"];

    private static int SizeRank(string size)
    {
        var index = Array.IndexOf(SizeOrder, size.ToUpperInvariant());
        if (index >= 0) return index;
        return decimal.TryParse(size, out var n) ? 100 + (int)(n * 10) : 10_000;
    }
}
