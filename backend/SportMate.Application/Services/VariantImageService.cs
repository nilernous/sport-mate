using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Product variants (UC-030 – UC-033) and product images (UC-034 – UC-037).</summary>
public class VariantImageService(IApplicationDbContext db, IFileStorage storage)
{
    public const long MaxImageBytes = 5 * 1024 * 1024;
    private static readonly Dictionary<string, string> AllowedImageTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        ["image/jpeg"] = ".jpg",
        ["image/png"] = ".png",
        ["image/webp"] = ".webp",
    };
    private const string UploadFolder = "uploads/products";

    // ---------- Variants ----------

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

    // ---------- Images ----------

    // UC-035
    public async Task<IReadOnlyList<ImageDto>> ListImagesAsync(int productId, CancellationToken ct)
    {
        await EnsureProductAsync(productId, ct);
        var images = await db.ProductImages.AsNoTracking().Where(i => i.ProductId == productId)
            .OrderByDescending(i => i.IsPrimary).ThenBy(i => i.DisplayOrder).ThenBy(i => i.Id).ToListAsync(ct);
        return images.Select(i => i.ToDto()).ToList();
    }

    // UC-034: accepts an uploaded file or an external image URL (BR-019).
    public async Task<ImageDto> AddImageAsync(int productId, AddImageRequest r, CancellationToken ct)
    {
        await EnsureProductAsync(productId, ct);
        if ((r.File is null) == string.IsNullOrWhiteSpace(r.Url))
            throw AppException.BadRequest("Provide either an image file or an image URL.", "file");

        string url;
        if (r.File is not null)
        {
            if (r.File.Length == 0 || r.File.Length > MaxImageBytes)
                throw AppException.BadRequest("Image must be between 1 byte and 5 MB.", "file");
            if (!AllowedImageTypes.TryGetValue(r.File.ContentType, out var extension))
                throw AppException.BadRequest("Only JPEG, PNG and WebP images are allowed.", "file");

            url = await storage.SaveAsync(r.File.Content, UploadFolder, $"{productId}-{Guid.NewGuid():N}{extension}", ct);
        }
        else
        {
            url = r.Url!.Trim();
        }

        var existing = await db.ProductImages.Where(i => i.ProductId == productId).ToListAsync(ct);
        var isPrimary = r.IsPrimary || existing.Count == 0;
        if (isPrimary) existing.ForEach(i => i.IsPrimary = false);

        var image = new ProductImage
        {
            ProductId = productId, Url = url, AltText = TextNormalizer.Clean(r.AltText),
            DisplayOrder = r.DisplayOrder ?? (existing.Count == 0 ? 0 : existing.Max(i => i.DisplayOrder) + 1),
            IsPrimary = isPrimary, CreatedAt = DateTime.UtcNow,
        };
        db.ProductImages.Add(image);
        await db.SaveChangesAsync(ct);
        return image.ToDto();
    }

    // UC-036
    public async Task<ImageDto> UpdateImageAsync(int imageId, UpdateImageRequest r, CancellationToken ct)
    {
        var image = await db.ProductImages.FindAsync([imageId], ct) ?? throw AppException.NotFound("Image");
        if (r.IsPrimary && !image.IsPrimary)
        {
            await db.ProductImages.Where(i => i.ProductId == image.ProductId && i.IsPrimary)
                .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsPrimary, false), ct);
        }
        image.AltText = TextNormalizer.Clean(r.AltText);
        image.DisplayOrder = r.DisplayOrder;
        image.IsPrimary = r.IsPrimary || (image.IsPrimary && !await db.ProductImages.AnyAsync(i => i.ProductId == image.ProductId && i.Id != image.Id, ct));
        await db.SaveChangesAsync(ct);
        return image.ToDto();
    }

    // UC-037: removes the record and, for files we stored, the file itself.
    public async Task DeleteImageAsync(int imageId, CancellationToken ct)
    {
        var image = await db.ProductImages.FindAsync([imageId], ct) ?? throw AppException.NotFound("Image");
        db.ProductImages.Remove(image);
        await db.SaveChangesAsync(ct);

        if (image.IsPrimary)
        {
            var next = await db.ProductImages.Where(i => i.ProductId == image.ProductId)
                .OrderBy(i => i.DisplayOrder).ThenBy(i => i.Id).FirstOrDefaultAsync(ct);
            if (next is not null)
            {
                next.IsPrimary = true;
                await db.SaveChangesAsync(ct);
            }
        }

        await storage.DeleteAsync(image.Url, ct);
    }

    private async Task EnsureProductAsync(int productId, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId, ct)) throw AppException.NotFound("Product");
    }
}
