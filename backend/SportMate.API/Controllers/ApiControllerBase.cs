using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;

namespace SportMate.API.Controllers;

[ApiController]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    /// <summary>Id of the authenticated caller, from validated JWT claims (BR-006).</summary>
    protected int CurrentUserId => User.GetUserId();
}
