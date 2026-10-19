using System.ComponentModel.DataAnnotations;
using SportMate.Application.Common;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.DTOs.Requests;

public class AddCartItemRequest
{
    [Range(1, int.MaxValue)]
    public int VariantId { get; init; }

    [Range(1, 99)]
    public int Quantity { get; init; } = 1;
}

public class UpdateCartItemRequest
{
    [Range(1, 99)]
    public int Quantity { get; init; }
}

public class CheckoutPreviewRequest
{
    public int? AddressId { get; init; }

    [EnumDataType(typeof(ShippingMethod))]
    public ShippingMethod ShippingMethod { get; init; } = ShippingMethod.Standard;
}

/// <summary>
/// Totals, prices and the owner are deliberately absent: the server derives them (BR-033).
/// </summary>
public class PlaceOrderRequest
{
    [Range(1, int.MaxValue)]
    public int AddressId { get; init; }

    [Required, EnumDataType(typeof(ShippingMethod))]
    public ShippingMethod? ShippingMethod { get; init; }

    [Required, EnumDataType(typeof(PaymentMethod))]
    public PaymentMethod? PaymentMethod { get; init; }

    [StringLength(500)]
    public string? Note { get; init; }
}

public class CancelOrderRequest
{
    [StringLength(500)]
    public string? Reason { get; init; }
}

public class UpdateOrderStatusRequest
{
    [Required, EnumDataType(typeof(OrderStatus))]
    public OrderStatus? Status { get; init; }

    [StringLength(500)]
    public string? Note { get; init; }
}

public class OrderQuery : PageQuery
{
    public OrderStatus? Status { get; init; }
}

public class AdminOrderQuery : PageQuery
{
    /// <summary>Matches order code, customer name or customer email.</summary>
    [StringLength(100)]
    public string? Keyword { get; init; }

    public OrderStatus? Status { get; init; }
    public PaymentStatus? PaymentStatus { get; init; }
    public int? CustomerId { get; init; }
    public DateOnly? From { get; init; }
    public DateOnly? To { get; init; }
}

public class InitiatePaymentRequest
{
    [Required, EnumDataType(typeof(PaymentMethod))]
    public PaymentMethod? Method { get; init; }
}

public class ConfirmPaymentRequest
{
    /// <summary>Amount actually received, checked against the amount due (BR-052).</summary>
    [Range(typeof(decimal), "0", "1000000000000")]
    public decimal Amount { get; init; }

    [Required, StringLength(100, MinimumLength = 3)]
    public string TransferReference { get; init; } = string.Empty;

    [StringLength(500)]
    public string? Note { get; init; }
}

public class UpdatePaymentStatusRequest
{
    [Required, EnumDataType(typeof(PaymentStatus))]
    public PaymentStatus? Status { get; init; }

    [StringLength(500)]
    public string? Note { get; init; }
}

public class AddWishlistItemRequest
{
    [Range(1, int.MaxValue)]
    public int ProductId { get; init; }
}

public class AdjustStockRequest
{
    /// <summary>Positive to add stock, negative to remove. Zero is rejected.</summary>
    [Range(-1_000_000, 1_000_000)]
    public int QuantityChange { get; init; }

    [Required, StringLength(500, MinimumLength = 3)]
    public string Reason { get; init; } = string.Empty;
}

public class InventoryQuery : PageQuery
{
    [StringLength(100)]
    public string? Keyword { get; init; }

    public int? ProductId { get; init; }
    public int? VariantId { get; init; }

    /// <summary>Only variants at or below this stock level.</summary>
    [Range(0, int.MaxValue)]
    public int? MaxStock { get; init; }
}

public class StockMovementQuery : PageQuery
{
    public int? VariantId { get; init; }
    public int? ProductId { get; init; }
    public StockMovementType? Type { get; init; }
    public DateOnly? From { get; init; }
    public DateOnly? To { get; init; }
}
