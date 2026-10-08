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

public class CatalogListQuery
{
    [StringLength(100)]
    public string? Keyword { get; init; }

    public bool? IsActive { get; init; }
}
