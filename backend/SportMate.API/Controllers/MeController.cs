using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>The caller's own profile, addresses and wishlist.</summary>
[Route("api/v1/users/me")]
[Authorize]
public class MeController(AuthService auth, AddressService addresses, WishlistService wishlist) : ApiControllerBase
{
    /// <summary>UC-007 View own profile.</summary>
    [HttpGet]
    public async Task<ActionResult<UserDto>> GetProfile(CancellationToken ct) =>
        Ok(await auth.GetProfileAsync(CurrentUserId, ct));

    /// <summary>UC-008 Update own profile.</summary>
    [HttpPut]
    public async Task<ActionResult<UserDto>> UpdateProfile(UpdateProfileRequest request, CancellationToken ct) =>
        Ok(await auth.UpdateProfileAsync(CurrentUserId, request, ct));

    /// <summary>UC-006 Change password. Returns a new token; older tokens stop working.</summary>
    [HttpPut("password")]
    public async Task<ActionResult<AuthResponse>> ChangePassword(ChangePasswordRequest request, CancellationToken ct) =>
        Ok(await auth.ChangePasswordAsync(CurrentUserId, request, ct));

    /// <summary>UC-010 List own delivery addresses.</summary>
    [HttpGet("addresses")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<IReadOnlyList<AddressDto>>> ListAddresses(CancellationToken ct) =>
        Ok(await addresses.ListAsync(CurrentUserId, ct));

    /// <summary>UC-009 Create a delivery address.</summary>
    [HttpPost("addresses")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<AddressDto>> CreateAddress(AddressRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await addresses.CreateAsync(CurrentUserId, request, ct));

    /// <summary>UC-011 Update own delivery address.</summary>
    [HttpPut("addresses/{id:int}")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<AddressDto>> UpdateAddress(int id, AddressRequest request, CancellationToken ct) =>
        Ok(await addresses.UpdateAsync(CurrentUserId, id, request, ct));

    /// <summary>UC-012 Delete own delivery address.</summary>
    [HttpDelete("addresses/{id:int}")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<IActionResult> DeleteAddress(int id, CancellationToken ct)
    {
        await addresses.DeleteAsync(CurrentUserId, id, ct);
        return NoContent();
    }

    /// <summary>UC-073 View own wishlist.</summary>
    [HttpGet("wishlist")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<IReadOnlyList<WishlistItemDto>>> GetWishlist(CancellationToken ct) =>
        Ok(await wishlist.ListAsync(CurrentUserId, ct));

    /// <summary>UC-074 Add a product to the wishlist (idempotent).</summary>
    [HttpPost("wishlist/items")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<IReadOnlyList<WishlistItemDto>>> AddToWishlist(AddWishlistItemRequest request, CancellationToken ct)
    {
        var created = await wishlist.AddAsync(CurrentUserId, request.ProductId, ct);
        var items = await wishlist.ListAsync(CurrentUserId, ct);
        return created ? StatusCode(StatusCodes.Status201Created, items) : Ok(items);
    }

    /// <summary>UC-075 Remove a product from the wishlist.</summary>
    [HttpDelete("wishlist/items/{productId:int}")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<IActionResult> RemoveFromWishlist(int productId, CancellationToken ct)
    {
        await wishlist.RemoveAsync(CurrentUserId, productId, ct);
        return NoContent();
    }
}
