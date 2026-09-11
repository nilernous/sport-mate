namespace SportMate.Domain.Enums;

public enum UserRole
{
    Customer,
    Staff,
    Admin,
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipping,
    Completed,
    Cancelled,
}

public enum ShippingMethod
{
    Standard,
    Express,
}

public enum PaymentMethod
{
    COD,
    BankTransfer,
}

public enum PaymentStatus
{
    Pending,
    Paid,
    Failed,
    Refunded,
}

public enum DiscountType
{
    Percentage,
    FixedAmount,
}

public enum ReviewStatus
{
    Approved,
    Hidden,
    Rejected,
}

public enum StockMovementType
{
    ManualAdjustment,
    OrderPlaced,
    OrderCancelled,
}
