using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

[Route("api/v1/cart")]
[Authorize(Roles = Roles.Customer)]
public class CartController(CartService cart) : ApiControllerBase
{
    /// <summary>UC-046 View own cart.</summary>
    [HttpGet]
    public async Task<ActionResult<CartDto>> Get(CancellationToken ct) => Ok(await cart.GetAsync(CurrentUserId, ct));

    /// <summary>UC-047 Add an item to the cart.</summary>
    [HttpPost("items")]
    public async Task<ActionResult<CartDto>> AddItem(AddCartItemRequest request, CancellationToken ct) =>
        Ok(await cart.AddItemAsync(CurrentUserId, request, ct));

    /// <summary>UC-048 Update an item's quantity.</summary>
    [HttpPatch("items/{itemId:int}")]
    public async Task<ActionResult<CartDto>> UpdateItem(int itemId, UpdateCartItemRequest request, CancellationToken ct) =>
        Ok(await cart.UpdateItemAsync(CurrentUserId, itemId, request, ct));

    /// <summary>UC-049 Remove an item.</summary>
    [HttpDelete("items/{itemId:int}")]
    public async Task<ActionResult<CartDto>> RemoveItem(int itemId, CancellationToken ct) =>
        Ok(await cart.RemoveItemAsync(CurrentUserId, itemId, ct));

    /// <summary>UC-050 Clear the cart.</summary>
    [HttpDelete]
    public async Task<IActionResult> Clear(CancellationToken ct)
    {
        await cart.ClearAsync(CurrentUserId, ct);
        return NoContent();
    }
}

[Route("api/v1")]
[Authorize(Roles = Roles.Customer)]
public class CheckoutController(OrderService orders) : ApiControllerBase
{
    /// <summary>UC-051 / UC-066 / UC-067 Preview totals, optionally with a coupon. Nothing is saved.</summary>
    [HttpPost("checkout/preview")]
    public async Task<ActionResult<CheckoutPreviewDto>> Preview(CheckoutPreviewRequest request, CancellationToken ct) =>
        Ok(await orders.PreviewAsync(CurrentUserId, request, ct));

    /// <summary>UC-065 Validate a coupon against the current cart. Does not consume usage.</summary>
    [HttpPost("coupons/validate")]
    public async Task<ActionResult<CouponCheckDto>> ValidateCoupon(ValidateCouponRequest request, CancellationToken ct) =>
        Ok(await orders.ValidateCouponAsync(CurrentUserId, request.Code, ct));
}

[Route("api/v1/orders")]
[Authorize(Roles = Roles.Customer)]
public class OrdersController(OrderService orders, PaymentService payments) : ApiControllerBase
{
    /// <summary>
    /// UC-052 Place an order from the cart. Send an <c>Idempotency-Key</c> header to make retries safe:
    /// a repeated key returns the original order with 200 instead of creating a new one.
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<OrderDetailDto>> Place(
        PlaceOrderRequest request, [FromHeader(Name = "Idempotency-Key")] string? idempotencyKey, CancellationToken ct)
    {
        var (order, created) = await orders.PlaceOrderAsync(CurrentUserId, request, idempotencyKey, ct);
        return created ? CreatedAtAction(nameof(Get), new { id = order.Id }, order) : Ok(order);
    }

    /// <summary>UC-053 Own order history.</summary>
    [HttpGet]
    public async Task<ActionResult<PagedResult<OrderSummaryDto>>> List([FromQuery] OrderQuery query, CancellationToken ct) =>
        Ok(await orders.ListOwnAsync(CurrentUserId, query, ct));

    /// <summary>UC-054 Own order details.</summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<OrderDetailDto>> Get(int id, CancellationToken ct) =>
        Ok(await orders.GetOwnAsync(CurrentUserId, id, ct));

    /// <summary>UC-055 Cancel an own order while it is Pending or Confirmed.</summary>
    [HttpPost("{id:int}/cancel")]
    public async Task<ActionResult<OrderDetailDto>> Cancel(int id, CancelOrderRequest? request, CancellationToken ct) =>
        Ok(await orders.CancelOwnAsync(CurrentUserId, id, request?.Reason, ct));

    /// <summary>UC-058 Payment status of an own order.</summary>
    [HttpGet("{orderId:int}/payment")]
    public async Task<ActionResult<PaymentDto>> GetPayment(int orderId, CancellationToken ct) =>
        Ok(await payments.GetOwnAsync(CurrentUserId, orderId, ct));

    /// <summary>UC-059 Choose COD or bank transfer and get payment instructions.</summary>
    [HttpPost("{orderId:int}/payment")]
    public async Task<ActionResult<PaymentDto>> InitiatePayment(int orderId, InitiatePaymentRequest request, CancellationToken ct) =>
        Ok(await payments.InitiateAsync(CurrentUserId, orderId, request.Method!.Value, ct));
}
