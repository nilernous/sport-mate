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
public class CatalogController(CategoryBrandService categories, ProductService products, ReviewService reviews) : ApiControllerBase
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

    /// <summary>UC-038 / UC-040 / UC-041 / UC-042 Browse, search, filter and sort products.</summary>
    [HttpGet("products")]
    public async Task<ActionResult<PagedResult<ProductSummaryDto>>> ListProducts([FromQuery] ProductQuery query, CancellationToken ct) =>
        Ok(await products.SearchPublicAsync(query, ct));

    /// <summary>Values for the filter UI: categories, brands, sizes, colors and price range.</summary>
    [HttpGet("products/filters")]
    public async Task<ActionResult<FilterOptionsDto>> GetFilterOptions(CancellationToken ct) =>
        Ok(await products.GetFilterOptionsAsync(ct));

    /// <summary>UC-039 View product details.</summary>
    [HttpGet("products/{id:int}")]
    public async Task<ActionResult<ProductDetailDto>> GetProduct(int id, CancellationToken ct) =>
        Ok(await products.GetPublicAsync(id, ct));

    /// <summary>UC-069 View approved reviews of a product.</summary>
    [HttpGet("products/{id:int}/reviews")]
    public async Task<ActionResult<ProductReviewsDto>> ListReviews(int id, [FromQuery] PageQuery query, CancellationToken ct) =>
        Ok(await reviews.ListForProductAsync(id, query, ct));

    /// <summary>The caller's review of this product, and whether they may write one.</summary>
    [HttpGet("products/{id:int}/reviews/me")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<MyReviewStatusDto>> GetMyReview(int id, CancellationToken ct) =>
        Ok(await reviews.GetMyStatusAsync(CurrentUserId, id, ct));

    /// <summary>UC-068 Create a review for a purchased product.</summary>
    [HttpPost("products/{id:int}/reviews")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<ReviewDto>> CreateReview(int id, ReviewRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await reviews.CreateAsync(CurrentUserId, id, request, ct));
}

[Route("api/v1/reviews")]
[Authorize]
public class ReviewsController(ReviewService reviews) : ApiControllerBase
{
    /// <summary>UC-070 Update own review.</summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<ReviewDto>> Update(int id, ReviewRequest request, CancellationToken ct) =>
        Ok(await reviews.UpdateOwnAsync(CurrentUserId, id, request, ct));

    /// <summary>UC-071 Delete own review (Staff/Admin may delete any review).</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        await reviews.DeleteAsync(CurrentUserId, User.IsStaffOrAdmin(), id, ct);
        return NoContent();
    }
}
