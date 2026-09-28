using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

[Route("api/v1/auth")]
public class AuthController(AuthService auth) : ApiControllerBase
{
    /// <summary>UC-001 Register a customer account.</summary>
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await auth.RegisterAsync(request, ct));

    /// <summary>UC-002 Sign in.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken ct) =>
        Ok(await auth.LoginAsync(request, ct));

    /// <summary>UC-003 Sign out. Revokes every token issued to the caller.</summary>
    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        await auth.LogoutAsync(CurrentUserId, ct);
        return NoContent();
    }

    /// <summary>UC-004 Request a password reset. Always returns the same response.</summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<ActionResult<MessageResponse>> ForgotPassword(ForgotPasswordRequest request, CancellationToken ct)
    {
        await auth.ForgotPasswordAsync(request, ct);
        return Ok(new MessageResponse("If an account exists for this email, password reset instructions have been sent."));
    }

    /// <summary>UC-005 Reset a password with a reset token.</summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<ActionResult<MessageResponse>> ResetPassword(ResetPasswordRequest request, CancellationToken ct)
    {
        await auth.ResetPasswordAsync(request, ct);
        return Ok(new MessageResponse("Your password has been reset. Please sign in."));
    }
}
