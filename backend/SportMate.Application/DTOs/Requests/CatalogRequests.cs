using System.ComponentModel.DataAnnotations;
using SportMate.Application.Common;

namespace SportMate.Application.DTOs.Requests;

public class CategoryRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Name { get; init; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; init; }

    public bool IsActive { get; init; } = true;
}

public class BrandRequest
{
    [Required, StringLength(100, MinimumLength = 1)]
    public string Name { get; init; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; init; }

    [Url, StringLength(500)]
    public string? LogoUrl { get; init; }

    public bool IsActive { get; init; } = true;
}

public class ProductRequest
{
    [Required, StringLength(200, MinimumLength = 2)]
    public string Name { get; init; } = string.Empty;

    [StringLength(4000)]
    public string? Description { get; init; }

    [Range(1, int.MaxValue)]
    public int CategoryId { get; init; }

    [Range(1, int.MaxValue)]
    public int BrandId { get; init; }

    [Range(typeof(decimal), "0", "1000000000")]
    public decimal BasePrice { get; init; }

    public bool IsActive { get; init; } = true;
}

public class ProductStatusRequest
{
    [Required]
    public bool? IsActive { get; init; }
}

public class CreateVariantRequest
{
    [Required, StringLength(64, MinimumLength = 2)]
    public string Sku { get; init; } = string.Empty;

    [Required, StringLength(20)]
    public string Size { get; init; } = string.Empty;

    [Required, StringLength(50)]
    public string Color { get; init; } = string.Empty;

    [Range(typeof(decimal), "0", "1000000000")]
    public decimal Price { get; init; }

    /// <summary>Opening stock, recorded as the first inventory movement.</summary>
    [Range(0, 1_000_000)]
    public int InitialStock { get; init; }

    public bool IsActive { get; init; } = true;
}

public class ProductQuery : PageQuery
{
    [StringLength(100)]
    public string? Keyword { get; init; }

    public int? CategoryId { get; init; }
    public int? BrandId { get; init; }

    [Range(typeof(decimal), "0", "1000000000")]
    public decimal? MinPrice { get; init; }

    [Range(typeof(decimal), "0", "1000000000")]
    public decimal? MaxPrice { get; init; }

    [StringLength(20)]
    public string? Size { get; init; }

    [StringLength(50)]
    public string? Color { get; init; }

    /// <summary>Allow-listed: name, price, newest, rating (BR-021).</summary>
    [RegularExpression("^(?i)(name|price|newest|rating)$", ErrorMessage = "sortBy must be one of: name, price, newest, rating.")]
    public string? SortBy { get; init; }

    [RegularExpression("^(?i)(asc|desc)$", ErrorMessage = "sortOrder must be asc or desc.")]
    public string? SortOrder { get; init; }
}

public class AdminProductQuery : ProductQuery
{
    public bool? IsActive { get; init; }
}

public class CatalogListQuery
{
    [StringLength(100)]
    public string? Keyword { get; init; }

    public bool? IsActive { get; init; }
}
