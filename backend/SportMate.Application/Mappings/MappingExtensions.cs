using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Mappings;

public static class MappingExtensions
{
    public static UserDto ToDto(this User u) => new(u.Id, u.FullName, u.Email, u.PhoneNumber, u.Role);

    public static AdminUserDto ToAdminDto(this User u) =>
        new(u.Id, u.FullName, u.Email, u.PhoneNumber, u.Role, u.IsActive, u.CreatedAt, u.UpdatedAt);

    public static AddressDto ToDto(this UserAddress a) =>
        new(a.Id, a.RecipientName, a.PhoneNumber, a.AddressLine, a.Ward, a.District, a.City, a.IsDefault);

    public static VariantDto ToDto(this ProductVariant v) =>
        new(v.Id, v.ProductId, v.Sku, v.Size, v.Color, v.Price, v.StockQuantity, v.IsActive && v.StockQuantity > 0, v.IsActive);

    public static ImageDto ToDto(this ProductImage i) =>
        new(i.Id, i.ProductId, i.Url, i.AltText, i.DisplayOrder, i.IsPrimary);

    public static DeliveryAddressDto ToDeliveryAddress(this Order o) =>
        new(o.RecipientName, o.PhoneNumber, o.AddressLine, o.Ward, o.District, o.City);

    public static OrderItemDto ToDto(this OrderItem i) =>
        new(i.Id, i.ProductId, i.VariantId, i.ProductName, i.Sku, i.Size, i.Color, i.ImageUrl, i.UnitPrice, i.Quantity, i.LineTotal);

    public static CouponDto ToDto(this Coupon c) =>
        new(c.Id, c.Code, c.Description, c.DiscountType, c.DiscountValue, c.MaxDiscountAmount, c.MinOrderAmount,
            c.ApplicableCategoryId, c.ApplicableCategory?.Name, c.StartsAt, c.EndsAt, c.UsageLimit, c.PerUserLimit,
            c.UsedCount, c.IsActive, c.CreatedAt, c.UpdatedAt);
}
