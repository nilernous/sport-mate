using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Inventory, orders, payments and review moderation, shared by Staff and Admin.</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.StaffOrAdmin)]
public class AdminOperationsController(
    InventoryService inventory,
    OrderService orders,
    PaymentService payments,
    ReviewService reviews) : ApiControllerBase
{
    // ---------- Inventory ----------

    /// <summary>UC-043 Stock per variant.</summary>
    [HttpGet("inventory")]
    public async Task<ActionResult<PagedResult<InventoryItemDto>>> ListInventory([FromQuery] InventoryQuery query, CancellationToken ct) =>
        Ok(await inventory.ListAsync(query, ct));

    /// <summary>UC-044 Adjust stock with a reason.</summary>
    [HttpPatch("variants/{id:int}/stock")]
    public async Task<ActionResult<InventoryItemDto>> AdjustStock(int id, AdjustStockRequest request, CancellationToken ct) =>
        Ok(await inventory.AdjustAsync(CurrentUserId, id, request, ct));

    /// <summary>UC-045 Inventory movement history.</summary>
    [HttpGet("inventory/movements")]
    public async Task<ActionResult<PagedResult<StockMovementDto>>> ListMovements([FromQuery] StockMovementQuery query, CancellationToken ct) =>
        Ok(await inventory.ListMovementsAsync(query, ct));

    // ---------- Orders ----------

    /// <summary>UC-056 Search and list all orders.</summary>
    [HttpGet("orders")]
    public async Task<ActionResult<PagedResult<AdminOrderSummaryDto>>> ListOrders([FromQuery] AdminOrderQuery query, CancellationToken ct) =>
        Ok(await orders.ListAllAsync(query, ct));

    [HttpGet("orders/{id:int}")]
    public async Task<ActionResult<OrderDetailDto>> GetOrder(int id, CancellationToken ct) =>
        Ok(await orders.GetForStaffAsync(id, ct));

    /// <summary>UC-057 Move an order to its next status.</summary>
    [HttpPatch("orders/{id:int}/status")]
    public async Task<ActionResult<OrderDetailDto>> UpdateOrderStatus(int id, UpdateOrderStatusRequest request, CancellationToken ct) =>
        Ok(await orders.UpdateStatusAsync(CurrentUserId, id, request.Status!.Value, request.Note, ct));

    // ---------- Payments ----------

    [HttpGet("payments/{paymentId:int}")]
    public async Task<ActionResult<PaymentDto>> GetPayment(int paymentId, CancellationToken ct) =>
        Ok(await payments.GetForStaffAsync(paymentId, ct));

    /// <summary>UC-060 Confirm a manually verified bank transfer.</summary>
    [HttpPatch("payments/{paymentId:int}/confirm")]
    public async Task<ActionResult<PaymentDto>> ConfirmPayment(int paymentId, ConfirmPaymentRequest request, CancellationToken ct) =>
        Ok(await payments.ConfirmBankTransferAsync(CurrentUserId, paymentId, request, ct));

    /// <summary>Other permitted payment changes: COD collected, failed, refunded.</summary>
    [HttpPatch("payments/{paymentId:int}/status")]
    public async Task<ActionResult<PaymentDto>> UpdatePaymentStatus(int paymentId, UpdatePaymentStatusRequest request, CancellationToken ct) =>
        Ok(await payments.UpdateStatusAsync(CurrentUserId, paymentId, request.Status!.Value, request.Note, ct));

    // ---------- Reviews ----------

    /// <summary>UC-069 All reviews, any status, for moderation.</summary>
    [HttpGet("reviews")]
    public async Task<ActionResult<PagedResult<ReviewDto>>> ListReviews([FromQuery] AdminReviewQuery query, CancellationToken ct) =>
        Ok(await reviews.ListForModerationAsync(query, ct));

    /// <summary>UC-072 Approve, hide or reject a review.</summary>
    [HttpPatch("reviews/{id:int}/status")]
    public async Task<ActionResult<ReviewDto>> ModerateReview(int id, ModerateReviewRequest request, CancellationToken ct) =>
        Ok(await reviews.ModerateAsync(CurrentUserId, id, request.Status!.Value, ct));
}
