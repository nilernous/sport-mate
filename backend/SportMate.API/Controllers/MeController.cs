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
public class MeController(AuthService auth, AddressService addresses) : ApiControllerBase
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

    /// <summary>UC-010 List own delivery addresses, used to pick one at checkout.</summary>
    [HttpGet("addresses")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<IReadOnlyList<AddressDto>>> ListAddresses(CancellationToken ct) =>
        Ok(await addresses.ListAsync(CurrentUserId, ct));

    /// <summary>UC-009 Create a delivery address.</summary>
    [HttpPost("addresses")]
    [Authorize(Roles = Roles.Customer)]
    public async Task<ActionResult<AddressDto>> CreateAddress(AddressRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await addresses.CreateAsync(CurrentUserId, request, ct));
}
