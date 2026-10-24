using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.API.Requests;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Catalog management, shared by Staff and Admin (UC-018 – UC-037).</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.StaffOrAdmin)]
public class AdminCatalogController(
    CategoryBrandService categories,
    ProductService products,
    VariantImageService variantsAndImages) : ApiControllerBase
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

    [HttpGet("products/{productId:int}/variants")]
    public async Task<ActionResult<IReadOnlyList<VariantDto>>> ListVariants(int productId, CancellationToken ct) =>
        Ok(await variantsAndImages.ListVariantsAsync(productId, ct));

    [HttpPost("products/{productId:int}/variants")]
    public async Task<ActionResult<VariantDto>> CreateVariant(int productId, CreateVariantRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await variantsAndImages.CreateVariantAsync(CurrentUserId, productId, request, ct));

    [HttpGet("variants/{id:int}")]
    public async Task<ActionResult<VariantDto>> GetVariant(int id, CancellationToken ct) =>
        Ok(await variantsAndImages.GetVariantAsync(id, ct));

    [HttpPut("variants/{id:int}")]
    public async Task<ActionResult<VariantDto>> UpdateVariant(int id, UpdateVariantRequest request, CancellationToken ct) =>
        Ok(await variantsAndImages.UpdateVariantAsync(id, request, ct));

    [HttpDelete("variants/{id:int}")]
    public async Task<ActionResult<DeleteResultDto>> DeleteVariant(int id, CancellationToken ct) =>
        Ok(await variantsAndImages.DeleteVariantAsync(id, ct));

    // ---------- Images ----------

    [HttpGet("products/{productId:int}/images")]
    public async Task<ActionResult<IReadOnlyList<ImageDto>>> ListImages(int productId, CancellationToken ct) =>
        Ok(await variantsAndImages.ListImagesAsync(productId, ct));

    /// <summary>Upload an image file (multipart/form-data) or register an image URL.</summary>
    [HttpPost("products/{productId:int}/images")]
    [Consumes("multipart/form-data", "application/x-www-form-urlencoded")]
    [RequestSizeLimit(VariantImageService.MaxImageBytes + 64 * 1024)]
    public async Task<ActionResult<ImageDto>> AddImage(int productId, [FromForm] AddImageForm form, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await variantsAndImages.AddImageAsync(productId, form.ToRequest(), ct));

    [HttpPut("images/{id:int}")]
    public async Task<ActionResult<ImageDto>> UpdateImage(int id, UpdateImageRequest request, CancellationToken ct) =>
        Ok(await variantsAndImages.UpdateImageAsync(id, request, ct));

    [HttpDelete("images/{id:int}")]
    public async Task<IActionResult> DeleteImage(int id, CancellationToken ct)
    {
        await variantsAndImages.DeleteImageAsync(id, ct);
        return NoContent();
    }
}
