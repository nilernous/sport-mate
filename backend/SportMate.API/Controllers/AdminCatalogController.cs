using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Catalog management, shared by Staff and Admin (UC-018 – UC-030).</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.StaffOrAdmin)]
public class AdminCatalogController(
    CategoryBrandService categories,
    ProductService products,
    VariantService variants) : ApiControllerBase
{
    // ---------- Categories ----------

    [HttpGet("categories")]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> ListCategories([FromQuery] CatalogListQuery query, CancellationToken ct) =>
        Ok(await categories.ListCategoriesAsync(query, publicOnly: false, ct));

    [HttpGet("categories/{id:int}")]
    public async Task<ActionResult<CategoryDto>> GetCategory(int id, CancellationToken ct) =>
        Ok(await categories.GetCategoryAsync(id, publicOnly: false, ct));

    [HttpPost("categories")]
    public async Task<ActionResult<CategoryDto>> CreateCategory(CategoryRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await categories.CreateCategoryAsync(request, ct));

    [HttpPut("categories/{id:int}")]
    public async Task<ActionResult<CategoryDto>> UpdateCategory(int id, CategoryRequest request, CancellationToken ct) =>
        Ok(await categories.UpdateCategoryAsync(id, request, ct));

    [HttpDelete("categories/{id:int}")]
    public async Task<ActionResult<DeleteResultDto>> DeleteCategory(int id, CancellationToken ct) =>
        Ok(await categories.DeleteCategoryAsync(id, ct));

    // ---------- Brands ----------

    [HttpGet("brands")]
    public async Task<ActionResult<IReadOnlyList<BrandDto>>> ListBrands([FromQuery] CatalogListQuery query, CancellationToken ct) =>
        Ok(await categories.ListBrandsAsync(query, publicOnly: false, ct));

    [HttpGet("brands/{id:int}")]
    public async Task<ActionResult<BrandDto>> GetBrand(int id, CancellationToken ct) =>
        Ok(await categories.GetBrandAsync(id, publicOnly: false, ct));

    [HttpPost("brands")]
    public async Task<ActionResult<BrandDto>> CreateBrand(BrandRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await categories.CreateBrandAsync(request, ct));

    [HttpPut("brands/{id:int}")]
    public async Task<ActionResult<BrandDto>> UpdateBrand(int id, BrandRequest request, CancellationToken ct) =>
        Ok(await categories.UpdateBrandAsync(id, request, ct));

    [HttpDelete("brands/{id:int}")]
    public async Task<ActionResult<DeleteResultDto>> DeleteBrand(int id, CancellationToken ct) =>
        Ok(await categories.DeleteBrandAsync(id, ct));

    // ---------- Products ----------

    [HttpGet("products")]
    public async Task<ActionResult<PagedResult<ProductSummaryDto>>> ListProducts([FromQuery] AdminProductQuery query, CancellationToken ct) =>
        Ok(await products.SearchAdminAsync(query, ct));

    [HttpGet("products/{id:int}")]
    public async Task<ActionResult<ProductDetailDto>> GetProduct(int id, CancellationToken ct) =>
        Ok(await products.GetAdminAsync(id, ct));

    [HttpPost("products")]
    public async Task<ActionResult<ProductDetailDto>> CreateProduct(ProductRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await products.CreateAsync(request, ct));

    [HttpPut("products/{id:int}")]
    public async Task<ActionResult<ProductDetailDto>> UpdateProduct(int id, ProductRequest request, CancellationToken ct) =>
        Ok(await products.UpdateAsync(id, request, ct));

    [HttpPatch("products/{id:int}/status")]
    public async Task<ActionResult<ProductDetailDto>> SetProductStatus(int id, ProductStatusRequest request, CancellationToken ct) =>
        Ok(await products.SetStatusAsync(id, request.IsActive!.Value, ct));

    [HttpDelete("products/{id:int}")]
    public async Task<ActionResult<DeleteResultDto>> DeleteProduct(int id, CancellationToken ct) =>
        Ok(await products.DeleteAsync(id, ct));

    // ---------- Variants ----------

    [HttpPost("products/{productId:int}/variants")]
    public async Task<ActionResult<VariantDto>> CreateVariant(int productId, CreateVariantRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await variants.CreateVariantAsync(CurrentUserId, productId, request, ct));
}
