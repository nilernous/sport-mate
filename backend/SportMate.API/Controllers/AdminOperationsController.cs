using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportMate.API.Common;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Services;

namespace SportMate.API.Controllers;

/// <summary>Inventory, orders and payments, shared by Staff and Admin.</summary>
[Route("api/v1/admin")]
[Authorize(Roles = Roles.StaffOrAdmin)]
public class AdminOperationsController(
    InventoryService inventory) : ApiControllerBase
{
    // ---------- Inventory ----------

    /// <summary>UC-043 Stock per variant.</summary>
    [HttpGet("inventory")]
    public async Task<ActionResult<PagedResult<InventoryItemDto>>> ListInventory([FromQuery] InventoryQuery query, CancellationToken ct) =>
        Ok(await inventory.ListAsync(query, ct));

    /// <summary>UC-044 Adjust stock with a reason.</summary>
    [HttpPatch("variants/{id:int}/stock")]
    public async Task<ActionResult<InventoryItemDto>> AdjustStock(int id, AdjustStockRequest request, CancellationToken ct) =>
        Ok(await inventory.AdjustAsync(CurrentUserId, id, request, ct));

    /// <summary>UC-045 Inventory movement history.</summary>
    [HttpGet("inventory/movements")]
    public async Task<ActionResult<PagedResult<StockMovementDto>>> ListMovements([FromQuery] StockMovementQuery query, CancellationToken ct) =>
        Ok(await inventory.ListMovementsAsync(query, ct));
}
