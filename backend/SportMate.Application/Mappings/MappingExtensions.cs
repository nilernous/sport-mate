using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Mappings;

public static class MappingExtensions
{
    public static UserDto ToDto(this User u) => new(u.Id, u.FullName, u.Email, u.PhoneNumber, u.Role);

    public static AddressDto ToDto(this UserAddress a) =>
        new(a.Id, a.RecipientName, a.PhoneNumber, a.AddressLine, a.Ward, a.District, a.City, a.IsDefault);

}
