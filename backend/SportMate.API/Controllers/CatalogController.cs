using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Public catalog: only active products, categories and brands are exposed (BR-002, BR-014).</summary>
[Route("api/v1")]
[AllowAnonymous]
public class CatalogController(CategoryBrandService categories) : ApiControllerBase
{
    [HttpGet("categories")]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> ListCategories([FromQuery] CatalogListQuery query, CancellationToken ct) =>
        Ok(await categories.ListCategoriesAsync(query, publicOnly: true, ct));

    [HttpGet("categories/{id:int}")]
    public async Task<ActionResult<CategoryDto>> GetCategory(int id, CancellationToken ct) =>
        Ok(await categories.GetCategoryAsync(id, publicOnly: true, ct));

    [HttpGet("brands")]
    public async Task<ActionResult<IReadOnlyList<BrandDto>>> ListBrands([FromQuery] CatalogListQuery query, CancellationToken ct) =>
        Ok(await categories.ListBrandsAsync(query, publicOnly: true, ct));

    [HttpGet("brands/{id:int}")]
    public async Task<ActionResult<BrandDto>> GetBrand(int id, CancellationToken ct) =>
        Ok(await categories.GetBrandAsync(id, publicOnly: true, ct));
}
