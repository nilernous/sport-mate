using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Users, coupons and reports. Admin only; Staff receive 403 (BR-005, BR-067).</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.Admin)]
public class AdminOnlyController(UserAdminService users, CouponService coupons, ReportService reports) : ApiControllerBase
{
    // ---------- Users ----------

    /// <summary>UC-014 List and search users.</summary>
    [HttpGet("users")]
    public async Task<ActionResult<PagedResult<AdminUserDto>>> ListUsers([FromQuery] UserQuery query, CancellationToken ct) =>
        Ok(await users.ListAsync(query, ct));

    /// <summary>UC-014 View a user.</summary>
    [HttpGet("users/{id:int}")]
    public async Task<ActionResult<AdminUserDetailDto>> GetUser(int id, CancellationToken ct) =>
        Ok(await users.GetAsync(id, ct));

    /// <summary>UC-013 Create a user with any role.</summary>
    [HttpPost("users")]
    public async Task<ActionResult<AdminUserDto>> CreateUser(AdminCreateUserRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await users.CreateAsync(request, ct));

    /// <summary>UC-015 Update user information.</summary>
    [HttpPut("users/{id:int}")]
    public async Task<ActionResult<AdminUserDto>> UpdateUser(int id, AdminUpdateUserRequest request, CancellationToken ct) =>
        Ok(await users.UpdateAsync(id, request, ct));

    /// <summary>UC-016 Enable or disable an account.</summary>
    [HttpPatch("users/{id:int}/status")]
    public async Task<ActionResult<AdminUserDto>> SetUserStatus(int id, UpdateUserStatusRequest request, CancellationToken ct) =>
        Ok(await users.SetStatusAsync(CurrentUserId, id, request.IsActive!.Value, ct));

    /// <summary>UC-017 Assign or change a role.</summary>
    [HttpPatch("users/{id:int}/role")]
    public async Task<ActionResult<AdminUserDto>> SetUserRole(int id, UpdateUserRoleRequest request, CancellationToken ct) =>
        Ok(await users.SetRoleAsync(CurrentUserId, id, request.Role!.Value, ct));

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

    // ---------- Reports ----------

    /// <summary>UC-076 Sales and order dashboard. Defaults to the last 30 days.</summary>
    [HttpGet("dashboard/summary")]
    public async Task<ActionResult<DashboardSummaryDto>> Dashboard([FromQuery] ReportRangeQuery query, CancellationToken ct) =>
        Ok(await reports.GetDashboardAsync(query, ct));

    /// <summary>UC-077 Order report grouped by day or status.</summary>
    [HttpGet("reports/orders")]
    public async Task<ActionResult<OrderReportDto>> OrderReport([FromQuery] OrderReportQuery query, CancellationToken ct) =>
        Ok(await reports.GetOrderReportAsync(query, ct));

    /// <summary>UC-078 Best-selling products.</summary>
    [HttpGet("reports/top-products")]
    public async Task<ActionResult<TopProductsReportDto>> TopProducts([FromQuery] TopProductsQuery query, CancellationToken ct) =>
        Ok(await reports.GetTopProductsAsync(query, ct));
}
