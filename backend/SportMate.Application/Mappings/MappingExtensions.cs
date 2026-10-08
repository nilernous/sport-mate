using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Mappings;

public static class MappingExtensions
{
    public static UserDto ToDto(this User u) => new(u.Id, u.FullName, u.Email, u.PhoneNumber, u.Role);

    public static AddressDto ToDto(this UserAddress a) =>
        new(a.Id, a.RecipientName, a.PhoneNumber, a.AddressLine, a.Ward, a.District, a.City, a.IsDefault);

    public static VariantDto ToDto(this ProductVariant v) =>
        new(v.Id, v.ProductId, v.Sku, v.Size, v.Color, v.Price, v.StockQuantity, v.IsActive && v.StockQuantity > 0, v.IsActive);

    public static ImageDto ToDto(this ProductImage i) =>
        new(i.Id, i.ProductId, i.Url, i.AltText, i.DisplayOrder, i.IsPrimary);

}
