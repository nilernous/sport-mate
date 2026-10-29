using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Coupons. Admin only; Staff receive 403 (BR-005, BR-067).</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.Admin)]
public class AdminOnlyController(CouponService coupons) : ApiControllerBase
{
    // ---------- Coupons ----------

    /// <summary>UC-062 List coupons.</summary>
    [HttpGet("coupons")]
    public async Task<ActionResult<PagedResult<CouponDto>>> ListCoupons([FromQuery] CouponQuery query, CancellationToken ct) =>
        Ok(await coupons.ListAsync(query, ct));

    /// <summary>UC-062 View a coupon.</summary>
    [HttpGet("coupons/{id:int}")]
    public async Task<ActionResult<CouponDto>> GetCoupon(int id, CancellationToken ct) =>
        Ok(await coupons.GetAsync(id, ct));

    /// <summary>UC-061 Create a coupon.</summary>
    [HttpPost("coupons")]
    public async Task<ActionResult<CouponDto>> CreateCoupon(CouponRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await coupons.CreateAsync(request, ct));

    /// <summary>UC-063 Update a coupon.</summary>
    [HttpPut("coupons/{id:int}")]
    public async Task<ActionResult<CouponDto>> UpdateCoupon(int id, CouponRequest request, CancellationToken ct) =>
        Ok(await coupons.UpdateAsync(id, request, ct));

    /// <summary>UC-064 Delete (or deactivate, if used) a coupon.</summary>
    [HttpDelete("coupons/{id:int}")]
    public async Task<ActionResult<DeleteResultDto>> DeleteCoupon(int id, CancellationToken ct) =>
        Ok(await coupons.DeleteAsync(id, ct));
}
