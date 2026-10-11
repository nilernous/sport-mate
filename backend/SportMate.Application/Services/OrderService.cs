using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Checkout and order lifecycle (UC-051 – UC-057, UC-066, UC-067).</summary>
public class OrderService(
    IApplicationDbContext db,
    CartService carts,
    CouponService coupons,
    InventoryService inventory,
    PaymentService payments,
    IOptions<ShippingSettings> shippingOptions,
    ReportSettingsAccessor reportSettings)
{
    private readonly ShippingSettings _shipping = shippingOptions.Value;

    /// <summary>Allowed order-state transitions (BR-040, BR-041).</summary>
    public static readonly IReadOnlyDictionary<OrderStatus, OrderStatus[]> Transitions = new Dictionary<OrderStatus, OrderStatus[]>
    {
        [OrderStatus.Pending] = [OrderStatus.Confirmed, OrderStatus.Cancelled],
        [OrderStatus.Confirmed] = [OrderStatus.Shipping, OrderStatus.Cancelled],
        [OrderStatus.Shipping] = [OrderStatus.Completed],
        [OrderStatus.Completed] = [],
        [OrderStatus.Cancelled] = [],
    };

    /// <summary>Customers may cancel before the order ships (BR-042).</summary>
    public static bool IsCustomerCancellable(OrderStatus status) => status is OrderStatus.Pending or OrderStatus.Confirmed;

    // ---------- Checkout ----------

    private sealed record PricedCart(List<CartItemDto> Items, List<CouponService.PricedLine> Lines, decimal Subtotal, List<string> Problems);

    private async Task<PricedCart> PriceCartAsync(int userId, CancellationToken ct)
    {
        var items = await carts.GetItemsAsync(userId, ct);
        var productIds = items.Select(i => i.ProductId).Distinct().ToList();
        var categoryByProduct = await db.Products.Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id, p => p.CategoryId, ct);

        var problems = new List<string>();
        if (items.Count == 0) problems.Add("Your cart is empty.");
        foreach (var item in items.Where(i => !i.IsAvailable))
        {
            problems.Add(item.AvailableStock > 0 && item.AvailableStock < item.Quantity
                ? $"{item.ProductName} ({item.Color}/{item.Size}): only {item.AvailableStock} left."
                : $"{item.ProductName} ({item.Color}/{item.Size}) is no longer available.");
        }

        var available = items.Where(i => i.IsAvailable).ToList();
        var lines = available.Select(i => new CouponService.PricedLine(i.ProductId, categoryByProduct[i.ProductId], i.LineTotal)).ToList();
        return new PricedCart(items, lines, available.Sum(i => i.LineTotal), problems);
    }

    // UC-051, UC-066, UC-067: nothing is persisted; the coupon is only previewed.
    public async Task<CheckoutPreviewDto> PreviewAsync(int userId, CheckoutPreviewRequest r, CancellationToken ct)
    {
        var priced = await PriceCartAsync(userId, ct);
        var problems = priced.Problems;

        AddressDto? address = null;
        if (r.AddressId is not null)
        {
            var owned = await db.UserAddresses.AsNoTracking().SingleOrDefaultAsync(a => a.Id == r.AddressId && a.UserId == userId, ct);
            if (owned is null) problems.Add("The selected delivery address was not found.");
            else address = owned.ToDto();
        }
        else
        {
            problems.Add("Select a delivery address.");
        }

        CouponCheckDto? couponCheck = null;
        decimal discount = 0;
        if (!string.IsNullOrWhiteSpace(r.CouponCode))
        {
            var evaluation = await coupons.EvaluateAsync(r.CouponCode, userId, priced.Lines, ct);
            couponCheck = evaluation.ToDto(r.CouponCode);
            discount = evaluation.DiscountAmount;
        }

        var shippingFee = priced.Items.Count == 0 ? 0 : _shipping.FeeFor(r.ShippingMethod, priced.Subtotal - discount);
        return new CheckoutPreviewDto(
            priced.Items, address, r.ShippingMethod, ShippingOptions(priced.Subtotal - discount), couponCheck,
            priced.Subtotal, discount, shippingFee, priced.Subtotal - discount + shippingFee,
            problems.Count == 0 && couponCheck?.IsValid != false, problems);
    }

    // UC-065
    public async Task<CouponCheckDto> ValidateCouponAsync(int userId, string code, CancellationToken ct)
    {
        var priced = await PriceCartAsync(userId, ct);
        return (await coupons.EvaluateAsync(code, userId, priced.Lines, ct)).ToDto(code);
    }

    public IReadOnlyList<ShippingOptionDto> ShippingOptions(decimal discountedSubtotal) =>
    [
        new(ShippingMethod.Standard, _shipping.FeeFor(ShippingMethod.Standard, discountedSubtotal),
            _shipping.FreeStandardShippingThreshold > 0
                ? $"3-5 days. Free for orders from {_shipping.FreeStandardShippingThreshold:N0} VND."
                : "3-5 days."),
        new(ShippingMethod.Express, _shipping.FeeFor(ShippingMethod.Express, discountedSubtotal), "1-2 days."),
    ];

    // ---------- Place order ----------

    // UC-052: validate everything, then create order, reduce stock and record coupon usage in one transaction (BR-035, BR-074).
    public async Task<(OrderDetailDto Order, bool Created)> PlaceOrderAsync(int userId, PlaceOrderRequest r, string? idempotencyKey, CancellationToken ct)
    {
        idempotencyKey = TextNormalizer.Clean(idempotencyKey);
        if (idempotencyKey is { Length: > 64 }) throw AppException.BadRequest("Idempotency-Key must be at most 64 characters.");
        if (idempotencyKey is not null)
        {
            // A retried submission returns the order that was already created (BR-036).
            var existingId = await db.Orders.Where(o => o.UserId == userId && o.IdempotencyKey == idempotencyKey)
                .Select(o => (int?)o.Id).SingleOrDefaultAsync(ct);
            if (existingId is not null) return (await GetDetailAsync(existingId.Value, ct), false);
        }

        var address = await db.UserAddresses.AsNoTracking().SingleOrDefaultAsync(a => a.Id == r.AddressId && a.UserId == userId, ct)
                      ?? throw AppException.BadRequest("The selected delivery address was not found.", "addressId");

        var priced = await PriceCartAsync(userId, ct);
        if (priced.Problems.Count > 0) throw AppException.Conflict(string.Join(" ", priced.Problems));

        // The coupon is re-checked here even if the preview accepted it (BR-058).
        CouponService.Evaluation? evaluation = null;
        if (!string.IsNullOrWhiteSpace(r.CouponCode))
        {
            evaluation = await coupons.EvaluateAsync(r.CouponCode, userId, priced.Lines, ct);
            if (!evaluation.IsValid) throw AppException.Conflict(evaluation.Message);
        }

        var discount = evaluation?.DiscountAmount ?? 0;
        var shippingFee = _shipping.FeeFor(r.ShippingMethod!.Value, priced.Subtotal - discount);
        var total = priced.Subtotal - discount + shippingFee;
        var now = DateTime.UtcNow;

        var order = new Order
        {
            OrderCode = NewOrderCode(now),
            UserId = userId,
            Status = OrderStatus.Pending,
            ShippingMethod = r.ShippingMethod.Value,
            Subtotal = priced.Subtotal,
            DiscountAmount = discount,
            ShippingFee = shippingFee,
            TotalAmount = total,
            CouponId = evaluation?.Coupon?.Id,
            CouponCode = evaluation?.Coupon?.Code,
            RecipientName = address.RecipientName,
            PhoneNumber = address.PhoneNumber,
            AddressLine = address.AddressLine,
            Ward = address.Ward,
            District = address.District,
            City = address.City,
            Note = TextNormalizer.Clean(r.Note),
            IdempotencyKey = idempotencyKey,
            CreatedAt = now,
            UpdatedAt = now,
            Items = priced.Items.Select(i => new OrderItem
            {
                ProductId = i.ProductId, VariantId = i.VariantId, ProductName = i.ProductName, Sku = i.Sku,
                Size = i.Size, Color = i.Color, ImageUrl = i.ImageUrl, UnitPrice = i.UnitPrice, Quantity = i.Quantity,
                LineTotal = i.LineTotal,
            }).ToList(),
            StatusHistory = [new OrderStatusHistory { ToStatus = OrderStatus.Pending, ChangedByUserId = userId, ChangedAt = now, Note = "Order placed" }],
            Payment = new Payment
            {
                Method = r.PaymentMethod!.Value, Status = PaymentStatus.Pending, Amount = total, CreatedAt = now, UpdatedAt = now,
            },
        };

        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Stock is deducted at order creation; the conditional update rejects overselling (BR-024, BR-025).
        var movements = new List<StockMovement>();
        foreach (var item in priced.Items)
        {
            var after = await inventory.ChangeStockAsync(item.VariantId, -item.Quantity, ct)
                        ?? throw AppException.Conflict($"{item.ProductName} ({item.Color}/{item.Size}) just sold out. Please review your cart.");
            movements.Add(new StockMovement
            {
                VariantId = item.VariantId, QuantityChange = -item.Quantity, QuantityAfter = after,
                Type = StockMovementType.OrderPlaced, ActorUserId = userId, CreatedAt = now,
            });
        }

        if (evaluation?.Coupon is { } coupon)
        {
            var claimed = await db.Coupons
                .Where(c => c.Id == coupon.Id && c.IsActive && (c.UsageLimit == null || c.UsedCount < c.UsageLimit))
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.UsedCount, c => c.UsedCount + 1), ct);
            if (claimed == 0) throw AppException.Conflict("This coupon has just reached its usage limit.");
        }

        db.Orders.Add(order);
        await db.SaveChangesAsync(ct);

        movements.ForEach(m => m.OrderId = order.Id);
        db.StockMovements.AddRange(movements);
        if (evaluation?.Coupon is { } usedCoupon)
        {
            db.CouponUsages.Add(new CouponUsage
            {
                CouponId = usedCoupon.Id, UserId = userId, OrderId = order.Id, DiscountAmount = discount, UsedAt = now,
            });
        }
        await db.SaveChangesAsync(ct);

        // Purchased lines leave the cart (BR-037).
        var purchasedItemIds = priced.Items.Select(i => i.Id).ToList();
        await db.CartItems.Where(i => purchasedItemIds.Contains(i.Id)).ExecuteDeleteAsync(ct);

        await tx.CommitAsync(ct);
        return (await GetDetailAsync(order.Id, ct), true);
    }

    private static string NewOrderCode(DateTime now) =>
        $"SM{now:yyMMdd}{RandomNumberGenerator.GetString("ABCDEFGHJKLMNPQRSTUVWXYZ23456789", 6)}";

    // ---------- Customer views ----------

    // UC-053
    public async Task<PagedResult<OrderSummaryDto>> ListOwnAsync(int userId, OrderQuery q, CancellationToken ct)
    {
        var query = db.Orders.AsNoTracking().Where(o => o.UserId == userId);
        if (q.Status is not null) query = query.Where(o => o.Status == q.Status);

        return await query.OrderByDescending(o => o.CreatedAt).ThenByDescending(o => o.Id)
            .Select(o => new OrderSummaryDto(
                o.Id, o.OrderCode, o.Status,
                o.Payment != null ? o.Payment.Method : null, o.Payment != null ? o.Payment.Status : null,
                o.TotalAmount, o.Items.Sum(i => i.Quantity),
                o.Items.OrderBy(i => i.Id).Select(i => i.ProductName).FirstOrDefault(),
                o.Items.OrderBy(i => i.Id).Select(i => i.ImageUrl).FirstOrDefault(),
                o.CreatedAt))
            .ToPagedResultAsync(q, ct);
    }

    // UC-054: another customer's order is reported as not found, not forbidden (BR-038).
    public async Task<OrderDetailDto> GetOwnAsync(int userId, int orderId, CancellationToken ct)
    {
        if (!await db.Orders.AnyAsync(o => o.Id == orderId && o.UserId == userId, ct)) throw AppException.NotFound("Order");
        return await GetDetailAsync(orderId, ct);
    }

    // UC-055
    public async Task<OrderDetailDto> CancelOwnAsync(int userId, int orderId, string? reason, CancellationToken ct)
    {
        if (!await db.Orders.AnyAsync(o => o.Id == orderId && o.UserId == userId, ct)) throw AppException.NotFound("Order");
        await CancelAsync(orderId, userId, isCustomer: true, TextNormalizer.Clean(reason) ?? "Cancelled by customer", ct);
        return await GetDetailAsync(orderId, ct);
    }

    // ---------- Staff / Admin ----------

    // UC-056
    public async Task<PagedResult<AdminOrderSummaryDto>> ListAllAsync(AdminOrderQuery q, CancellationToken ct)
    {
        var (fromUtc, toUtc) = reportSettings.ToUtcRange(q.From, q.To, requireRange: false);
        var query = db.Orders.AsNoTracking();
        if (q.Status is not null) query = query.Where(o => o.Status == q.Status);
        if (q.PaymentStatus is not null) query = query.Where(o => o.Payment != null && o.Payment.Status == q.PaymentStatus);
        if (q.CustomerId is not null) query = query.Where(o => o.UserId == q.CustomerId);
        if (fromUtc is not null) query = query.Where(o => o.CreatedAt >= fromUtc);
        if (toUtc is not null) query = query.Where(o => o.CreatedAt < toUtc);
        if (!string.IsNullOrWhiteSpace(q.Keyword))
        {
            var k = q.Keyword.Trim();
            query = query.Where(o => o.OrderCode.Contains(k) || o.User.FullName.Contains(k) || o.User.Email.Contains(k) || o.PhoneNumber.Contains(k));
        }

        return await query.OrderByDescending(o => o.CreatedAt).ThenByDescending(o => o.Id)
            .Select(o => new AdminOrderSummaryDto(
                o.Id, o.OrderCode, o.UserId, o.User.FullName, o.User.Email, o.Status,
                o.Payment != null ? o.Payment.Method : null, o.Payment != null ? o.Payment.Status : null,
                o.TotalAmount, o.Items.Sum(i => i.Quantity), o.CreatedAt))
            .ToPagedResultAsync(q, ct);
    }

    public Task<OrderDetailDto> GetForStaffAsync(int orderId, CancellationToken ct) => GetDetailAsync(orderId, ct);

    // UC-057
    public async Task<OrderDetailDto> UpdateStatusAsync(int actorId, int orderId, OrderStatus target, string? note, CancellationToken ct)
    {
        if (target == OrderStatus.Cancelled)
        {
            await CancelAsync(orderId, actorId, isCustomer: false, TextNormalizer.Clean(note) ?? "Cancelled by staff", ct);
            return await GetDetailAsync(orderId, ct);
        }

        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var order = await db.Orders.Include(o => o.Payment).SingleOrDefaultAsync(o => o.Id == orderId, ct)
                    ?? throw AppException.NotFound("Order");
        EnsureTransition(order.Status, target);

        // Payment rules cannot be bypassed by a status change (BR-043).
        if (target == OrderStatus.Shipping && order.Payment is { Method: PaymentMethod.BankTransfer, Status: not PaymentStatus.Paid })
            throw AppException.Conflict("A bank-transfer order can be shipped only after its payment is confirmed.");

        var now = DateTime.UtcNow;
        var from = order.Status;
        order.Status = target;
        order.UpdatedAt = now;
        order.StatusHistory.Add(new OrderStatusHistory { FromStatus = from, ToStatus = target, ChangedByUserId = actorId, ChangedAt = now, Note = TextNormalizer.Clean(note) });

        // COD: delivering the order is the agreed confirmation that cash was collected (BR-049).
        if (target == OrderStatus.Completed && order.Payment is { Method: PaymentMethod.COD, Status: PaymentStatus.Pending } cod)
            payments.MarkPaid(cod, actorId, now, "Cash collected on delivery");

        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return await GetDetailAsync(orderId, ct);
    }

    /// <summary>
    /// Cancels an order and restores its stock exactly once (BR-028). The status change is saved first
    /// under the order's row version, so a concurrent second cancellation fails with 409 instead of
    /// restoring stock twice.
    /// </summary>
    private async Task CancelAsync(int orderId, int actorId, bool isCustomer, string note, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var order = await db.Orders.Include(o => o.Items).Include(o => o.Payment)
                        .SingleOrDefaultAsync(o => o.Id == orderId, ct) ?? throw AppException.NotFound("Order");

        if (isCustomer && !IsCustomerCancellable(order.Status))
            throw AppException.Conflict("This order can no longer be cancelled because it has already shipped or been closed.");
        EnsureTransition(order.Status, OrderStatus.Cancelled);

        var now = DateTime.UtcNow;
        var from = order.Status;
        order.Status = OrderStatus.Cancelled;
        order.CancelledAt = now;
        order.UpdatedAt = now;
        order.StatusHistory.Add(new OrderStatusHistory { FromStatus = from, ToStatus = OrderStatus.Cancelled, ChangedByUserId = actorId, ChangedAt = now, Note = note });

        if (order.Payment is { } payment)
        {
            if (payment.Status == PaymentStatus.Pending)
            {
                payment.Status = PaymentStatus.Failed;
                payment.Note = "Order cancelled before payment";
                payment.UpdatedAt = now;
            }
            else if (payment.Status == PaymentStatus.Paid)
            {
                // Cancelling a paid order does not refund it automatically (BR-053).
                payment.Note = "Order cancelled after payment: refund pending";
                payment.UpdatedAt = now;
            }
        }
        await db.SaveChangesAsync(ct);

        foreach (var item in order.Items)
        {
            var after = await inventory.ChangeStockAsync(item.VariantId, item.Quantity, ct)
                        ?? throw AppException.Conflict("Stock could not be restored.");
            db.StockMovements.Add(new StockMovement
            {
                VariantId = item.VariantId, QuantityChange = item.Quantity, QuantityAfter = after,
                Type = StockMovementType.OrderCancelled, OrderId = order.Id, ActorUserId = actorId, CreatedAt = now,
            });
        }

        // A cancelled order gives its coupon use back.
        if (order.CouponId is not null)
        {
            var released = await db.CouponUsages.Where(u => u.OrderId == order.Id).ExecuteDeleteAsync(ct);
            if (released > 0)
            {
                await db.Coupons.Where(c => c.Id == order.CouponId && c.UsedCount > 0)
                    .ExecuteUpdateAsync(s => s.SetProperty(c => c.UsedCount, c => c.UsedCount - 1), ct);
            }
        }

        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
    }

    private static void EnsureTransition(OrderStatus from, OrderStatus to)
    {
        if (!Transitions[from].Contains(to))
            throw AppException.Conflict($"An order cannot move from {from} to {to}.");
    }

    // ---------- Detail ----------

    public async Task<OrderDetailDto> GetDetailAsync(int orderId, CancellationToken ct)
    {
        var o = await db.Orders.AsNoTracking().AsSplitQuery()
            .Include(x => x.User)
            .Include(x => x.Items)
            .Include(x => x.StatusHistory).ThenInclude(h => h.ChangedByUser)
            .Include(x => x.Payment).ThenInclude(p => p!.ConfirmedByUser)
            .SingleOrDefaultAsync(x => x.Id == orderId, ct) ?? throw AppException.NotFound("Order");

        return new OrderDetailDto(
            o.Id, o.OrderCode, o.UserId, o.User.FullName, o.Status, o.ShippingMethod, o.Subtotal, o.DiscountAmount,
            o.ShippingFee, o.TotalAmount, o.CouponCode, o.ToDeliveryAddress(), o.Note,
            o.Items.OrderBy(i => i.Id).Select(i => i.ToDto()).ToList(),
            o.Payment is null ? null : payments.ToDto(o.Payment, o.OrderCode),
            o.StatusHistory.OrderBy(h => h.ChangedAt).ThenBy(h => h.Id)
                .Select(h => new OrderStatusHistoryDto(h.FromStatus, h.ToStatus, h.ChangedByUser?.FullName, h.Note, h.ChangedAt)).ToList(),
            IsCustomerCancellable(o.Status), Transitions[o.Status], o.CreatedAt, o.UpdatedAt);
    }
}
