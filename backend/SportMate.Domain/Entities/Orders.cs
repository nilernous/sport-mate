using SportMate.Domain.Enums;

namespace SportMate.Domain.Entities;

public class Order
{
    public int Id { get; set; }

    /// <summary>Human-readable reference, also used as the bank-transfer reference.</summary>
    public string OrderCode { get; set; } = string.Empty;

    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public ShippingMethod ShippingMethod { get; set; }

    public decimal Subtotal { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal ShippingFee { get; set; }
    public decimal TotalAmount { get; set; }

    public int? CouponId { get; set; }
    public string? CouponCode { get; set; }

    // Delivery address snapshot (BR-013)
    public string RecipientName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string AddressLine { get; set; } = string.Empty;
    public string Ward { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;

    public string? Note { get; set; }
    public string? IdempotencyKey { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? CancelledAt { get; set; }

    public byte[] RowVersion { get; set; } = [];

    public List<OrderItem> Items { get; set; } = [];
    public List<OrderStatusHistory> StatusHistory { get; set; } = [];
    public Payment? Payment { get; set; }
}

/// <summary>Snapshot of what was bought, at the price paid (BR-039).</summary>
public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public int ProductId { get; set; }
    public int VariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public string Size { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal LineTotal { get; set; }
}

public class OrderStatusHistory
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public OrderStatus? FromStatus { get; set; }
    public OrderStatus ToStatus { get; set; }
    public int? ChangedByUserId { get; set; }
    public User? ChangedByUser { get; set; }
    public string? Note { get; set; }
    public DateTime ChangedAt { get; set; }
}

public class Payment
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public PaymentMethod Method { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public decimal Amount { get; set; }
    public string? TransferReference { get; set; }
    public int? ConfirmedByUserId { get; set; }
    public User? ConfirmedByUser { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public byte[] RowVersion { get; set; } = [];
}
