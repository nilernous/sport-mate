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
