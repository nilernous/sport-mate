using SportMate.Application.Common;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.DTOs.Responses;

// ---------- Auth & users ----------

public record UserDto(int Id, string FullName, string Email, string? PhoneNumber, UserRole Role);

public record AuthResponse(string AccessToken, DateTime ExpiresAt, UserDto User);

public record MessageResponse(string Message);

public record AddressDto(
    int Id, string RecipientName, string PhoneNumber, string AddressLine, string Ward, string District,
    string City, bool IsDefault);

// ---------- Catalog ----------

public record CategoryDto(int Id, string Name, string? Description, bool IsActive, int ProductCount);

public record BrandDto(int Id, string Name, string? Description, string? LogoUrl, bool IsActive, int ProductCount);

/// <summary>Result of a delete request that may fall back to deactivation (BR-020).</summary>
public record DeleteResultDto(string Action, string Message)
{
    public static DeleteResultDto Deleted(string resource) => new("Deleted", $"{resource} was deleted.");

    public static DeleteResultDto Deactivated(string resource, string reason) =>
        new("Deactivated", $"{resource} is referenced by {reason}, so it was deactivated instead of deleted.");
}

public record ProductSummaryDto(
    int Id, string Name, string CategoryName, string BrandName, decimal Price, string? ImageUrl,
    double AverageRating, int ReviewCount, bool InStock, bool IsActive);

public record VariantDto(
    int Id, int ProductId, string Sku, string Size, string Color, decimal Price, int StockQuantity, bool InStock,
    bool IsActive);

public record ImageDto(int Id, int ProductId, string Url, string? AltText, int DisplayOrder, bool IsPrimary);

public record ProductDetailDto(
    int Id, string Name, string? Description, int CategoryId, string CategoryName, int BrandId, string BrandName,
    decimal BasePrice, decimal Price, bool IsActive, double AverageRating, int ReviewCount,
    IReadOnlyList<ImageDto> Images, IReadOnlyList<VariantDto> Variants, DateTime CreatedAt, DateTime UpdatedAt);

public record FilterOptionsDto(
    IReadOnlyList<CategoryDto> Categories, IReadOnlyList<BrandDto> Brands, IReadOnlyList<string> Sizes,
    IReadOnlyList<string> Colors, decimal MinPrice, decimal MaxPrice);

// ---------- Inventory ----------

public record InventoryItemDto(
    int VariantId, int ProductId, string ProductName, string Sku, string Size, string Color, decimal Price,
    int StockQuantity, bool IsActive);

public record StockMovementDto(
    int Id, int VariantId, string Sku, string ProductName, int QuantityChange, int QuantityAfter,
    StockMovementType Type, string? Reason, int? OrderId, string? ActorName, DateTime CreatedAt);

// ---------- Cart & checkout ----------

public record CartItemDto(
    int Id, int VariantId, int ProductId, string ProductName, string Sku, string Size, string Color,
    string? ImageUrl, decimal UnitPrice, int Quantity, decimal LineTotal, int AvailableStock, bool IsAvailable);

/// <summary>Cart prices are indicative only (BR-031).</summary>
public record CartDto(IReadOnlyList<CartItemDto> Items, int TotalQuantity, decimal EstimatedSubtotal);

public record ShippingOptionDto(ShippingMethod Method, decimal Fee, string Description);

public record CheckoutPreviewDto(
    IReadOnlyList<CartItemDto> Items, AddressDto? Address, ShippingMethod ShippingMethod,
    IReadOnlyList<ShippingOptionDto> ShippingOptions, decimal Subtotal, decimal ShippingFee, decimal Total,
    bool CanPlaceOrder, IReadOnlyList<string> Problems);

// ---------- Orders & payments ----------

public record OrderItemDto(
    int Id, int ProductId, int VariantId, string ProductName, string Sku, string Size, string Color,
    string? ImageUrl, decimal UnitPrice, int Quantity, decimal LineTotal);

public record OrderStatusHistoryDto(OrderStatus? FromStatus, OrderStatus ToStatus, string? ChangedBy, string? Note, DateTime ChangedAt);

public record DeliveryAddressDto(string RecipientName, string PhoneNumber, string AddressLine, string Ward, string District, string City);

public record OrderDetailDto(
    int Id, string OrderCode, int CustomerId, string CustomerName, OrderStatus Status, ShippingMethod ShippingMethod,
    decimal Subtotal, decimal DiscountAmount, decimal ShippingFee, decimal TotalAmount, string? CouponCode,
    DeliveryAddressDto DeliveryAddress, string? Note, IReadOnlyList<OrderItemDto> Items, PaymentDto? Payment,
    IReadOnlyList<OrderStatusHistoryDto> StatusHistory, bool CanCancel, IReadOnlyList<OrderStatus> AllowedNextStatuses,
    DateTime CreatedAt, DateTime UpdatedAt);

public record BankTransferInstructionsDto(string BankName, string AccountNumber, string AccountName, decimal Amount, string TransferContent);

public record PaymentDto(
    int Id, int OrderId, string OrderCode, PaymentMethod Method, PaymentStatus Status, decimal Amount,
    string? TransferReference, string? ConfirmedBy, DateTime? ConfirmedAt, string? Note,
    BankTransferInstructionsDto? BankTransferInstructions, DateTime CreatedAt, DateTime UpdatedAt);

// ---------- Wishlist ----------

public record WishlistItemDto(int ProductId, string Name, decimal Price, string? ImageUrl, bool InStock, bool IsActive, DateTime AddedAt);
