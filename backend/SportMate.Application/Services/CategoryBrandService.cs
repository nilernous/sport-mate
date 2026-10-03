using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Categories (UC-018 – UC-021) and brands (UC-022 – UC-025).</summary>
public class CategoryBrandService(IApplicationDbContext db)
{
    // ---------- Categories ----------

    public async Task<IReadOnlyList<CategoryDto>> ListCategoriesAsync(CatalogListQuery q, bool publicOnly, CancellationToken ct)
    {
        var query = db.Categories.AsNoTracking();
        if (publicOnly) query = query.Where(c => c.IsActive);
        else if (q.IsActive is not null) query = query.Where(c => c.IsActive == q.IsActive);
        if (!string.IsNullOrWhiteSpace(q.Keyword)) query = query.Where(c => c.Name.Contains(q.Keyword.Trim()));

        return await query.OrderBy(c => c.Name)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Description, c.IsActive,
                c.Products.Count(p => !publicOnly || p.IsActive)))
            .ToListAsync(ct);
    }

    public async Task<CategoryDto> GetCategoryAsync(int id, bool publicOnly, CancellationToken ct) =>
        await db.Categories.AsNoTracking()
            .Where(c => c.Id == id && (!publicOnly || c.IsActive))
            .Select(c => new CategoryDto(c.Id, c.Name, c.Description, c.IsActive, c.Products.Count(p => !publicOnly || p.IsActive)))
            .SingleOrDefaultAsync(ct) ?? throw AppException.NotFound("Category");

    public async Task<CategoryDto> CreateCategoryAsync(CategoryRequest r, CancellationToken ct)
    {
        await EnsureUniqueCategoryNameAsync(r.Name, null, ct);
        var now = DateTime.UtcNow;
        var category = new Category
        {
            Name = r.Name.Trim(), Description = TextNormalizer.Clean(r.Description), IsActive = r.IsActive,
            CreatedAt = now, UpdatedAt = now,
        };
        db.Categories.Add(category);
        await db.SaveChangesAsync(ct);
        return await GetCategoryAsync(category.Id, false, ct);
    }

    public async Task<CategoryDto> UpdateCategoryAsync(int id, CategoryRequest r, CancellationToken ct)
    {
        var category = await db.Categories.FindAsync([id], ct) ?? throw AppException.NotFound("Category");
        await EnsureUniqueCategoryNameAsync(r.Name, id, ct);
        category.Name = r.Name.Trim();
        category.Description = TextNormalizer.Clean(r.Description);
        category.IsActive = r.IsActive;
        category.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetCategoryAsync(id, false, ct);
    }

    // Referenced categories are deactivated instead of deleted (BR-015, BR-020).
    public async Task<DeleteResultDto> DeleteCategoryAsync(int id, CancellationToken ct)
    {
        var category = await db.Categories.FindAsync([id], ct) ?? throw AppException.NotFound("Category");
        var referenced = await db.Products.AnyAsync(p => p.CategoryId == id, ct)
                         || await db.Coupons.AnyAsync(c => c.ApplicableCategoryId == id, ct);
        if (referenced)
        {
            category.IsActive = false;
            category.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            return DeleteResultDto.Deactivated("Category", "products or coupons");
        }

        db.Categories.Remove(category);
        await db.SaveChangesAsync(ct);
        return DeleteResultDto.Deleted("Category");
    }

    private async Task EnsureUniqueCategoryNameAsync(string name, int? exceptId, CancellationToken ct)
    {
        var trimmed = name.Trim();
        // SQL Server's default collation is case-insensitive, so this comparison is too.
        if (await db.Categories.AnyAsync(c => c.Name == trimmed && c.Id != exceptId, ct))
            throw AppException.Conflict($"Category '{trimmed}' already exists.");
    }

    // ---------- Brands ----------

    public async Task<IReadOnlyList<BrandDto>> ListBrandsAsync(CatalogListQuery q, bool publicOnly, CancellationToken ct)
    {
        var query = db.Brands.AsNoTracking();
        if (publicOnly) query = query.Where(b => b.IsActive);
        else if (q.IsActive is not null) query = query.Where(b => b.IsActive == q.IsActive);
        if (!string.IsNullOrWhiteSpace(q.Keyword)) query = query.Where(b => b.Name.Contains(q.Keyword.Trim()));

        return await query.OrderBy(b => b.Name)
            .Select(b => new BrandDto(b.Id, b.Name, b.Description, b.LogoUrl, b.IsActive,
                b.Products.Count(p => !publicOnly || p.IsActive)))
            .ToListAsync(ct);
    }

    public async Task<BrandDto> GetBrandAsync(int id, bool publicOnly, CancellationToken ct) =>
        await db.Brands.AsNoTracking()
            .Where(b => b.Id == id && (!publicOnly || b.IsActive))
            .Select(b => new BrandDto(b.Id, b.Name, b.Description, b.LogoUrl, b.IsActive, b.Products.Count(p => !publicOnly || p.IsActive)))
            .SingleOrDefaultAsync(ct) ?? throw AppException.NotFound("Brand");

    public async Task<BrandDto> CreateBrandAsync(BrandRequest r, CancellationToken ct)
    {
        await EnsureUniqueBrandNameAsync(r.Name, null, ct);
        var now = DateTime.UtcNow;
        var brand = new Brand
        {
            Name = r.Name.Trim(), Description = TextNormalizer.Clean(r.Description), LogoUrl = TextNormalizer.Clean(r.LogoUrl),
            IsActive = r.IsActive, CreatedAt = now, UpdatedAt = now,
        };
        db.Brands.Add(brand);
        await db.SaveChangesAsync(ct);
        return await GetBrandAsync(brand.Id, false, ct);
    }

    public async Task<BrandDto> UpdateBrandAsync(int id, BrandRequest r, CancellationToken ct)
    {
        var brand = await db.Brands.FindAsync([id], ct) ?? throw AppException.NotFound("Brand");
        await EnsureUniqueBrandNameAsync(r.Name, id, ct);
        brand.Name = r.Name.Trim();
        brand.Description = TextNormalizer.Clean(r.Description);
        brand.LogoUrl = TextNormalizer.Clean(r.LogoUrl);
        brand.IsActive = r.IsActive;
        brand.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetBrandAsync(id, false, ct);
    }

    public async Task<DeleteResultDto> DeleteBrandAsync(int id, CancellationToken ct)
    {
        var brand = await db.Brands.FindAsync([id], ct) ?? throw AppException.NotFound("Brand");
        if (await db.Products.AnyAsync(p => p.BrandId == id, ct))
        {
            brand.IsActive = false;
            brand.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            return DeleteResultDto.Deactivated("Brand", "products");
        }

        db.Brands.Remove(brand);
        await db.SaveChangesAsync(ct);
        return DeleteResultDto.Deleted("Brand");
    }

    private async Task EnsureUniqueBrandNameAsync(string name, int? exceptId, CancellationToken ct)
    {
        var trimmed = name.Trim();
        if (await db.Brands.AnyAsync(b => b.Name == trimmed && b.Id != exceptId, ct))
            throw AppException.Conflict($"Brand '{trimmed}' already exists.");
    }
}
