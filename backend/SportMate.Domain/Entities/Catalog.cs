using SportMate.Domain.Enums;

namespace SportMate.Domain.Entities;

public class Category
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<Product> Products { get; set; } = [];
}

public class Brand
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<Product> Products { get; set; } = [];
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int CategoryId { get; set; }
    public Category Category { get; set; } = null!;
    public int BrandId { get; set; }
    public Brand Brand { get; set; } = null!;

    /// <summary>Reference price shown when a product has no active variant yet.</summary>
    public decimal BasePrice { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<ProductVariant> Variants { get; set; } = [];
    public List<ProductImage> Images { get; set; } = [];
    public List<Review> Reviews { get; set; } = [];
}

public class ProductVariant
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;

    /// <summary>Stored upper-cased and trimmed so uniqueness is case-insensitive (BR-017).</summary>
    public string Sku { get; set; } = string.Empty;

    public string Size { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public decimal Price { get; set; }

    /// <summary>Available stock. Only changed through conditional updates so it never goes negative (BR-023, BR-075).</summary>
    public int StockQuantity { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class ProductImage
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;
    public string Url { get; set; } = string.Empty;
    public string? AltText { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsPrimary { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class StockMovement
{
    public int Id { get; set; }
    public int VariantId { get; set; }
    public ProductVariant Variant { get; set; } = null!;
    public int QuantityChange { get; set; }
    public int QuantityAfter { get; set; }
    public StockMovementType Type { get; set; }
    public string? Reason { get; set; }
    public int? OrderId { get; set; }
    public int? ActorUserId { get; set; }
    public User? ActorUser { get; set; }
    public DateTime CreatedAt { get; set; }
}
