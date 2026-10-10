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
