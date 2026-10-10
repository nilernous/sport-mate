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
