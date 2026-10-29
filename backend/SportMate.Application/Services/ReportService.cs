using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>
/// Admin reports (UC-076 – UC-078).
/// Revenue = amount of Paid payments of non-cancelled orders placed in the range; COD counts only
/// once collected (BR-068). Best-selling = quantity sold in those same orders (BR-070).
/// </summary>
public class ReportService(IApplicationDbContext db, ReportSettingsAccessor settings)
{
    public const string RevenueDefinition =
        "Sum of paid payments for non-cancelled orders placed in the range. COD counts only after collection; cancelled, unpaid and refunded orders are excluded.";
    public const string BestSellingDefinition =
        "Quantity sold in non-cancelled orders with a paid payment, placed in the range.";

    private IQueryable<Order> OrdersIn(DateTime fromUtc, DateTime toUtc) =>
        db.Orders.AsNoTracking().Where(o => o.CreatedAt >= fromUtc && o.CreatedAt < toUtc);

    private static IQueryable<Order> Revenue(IQueryable<Order> orders) =>
        orders.Where(o => o.Status != OrderStatus.Cancelled && o.Payment != null && o.Payment.Status == PaymentStatus.Paid);

    // UC-076
    public async Task<DashboardSummaryDto> GetDashboardAsync(ReportRangeQuery q, CancellationToken ct)
    {
        var (from, to, fromUtc, toUtc) = settings.ResolveReportRange(q.From, q.To);
        var orders = OrdersIn(fromUtc, toUtc);

        var byStatus = await orders.GroupBy(o => o.Status).Select(g => new { Status = g.Key, Count = g.Count() }).ToListAsync(ct);
        var paid = await Revenue(orders).Select(o => new { o.CreatedAt, o.TotalAmount }).ToListAsync(ct);
        var newCustomers = await db.Users.CountAsync(u => u.Role == UserRole.Customer && u.CreatedAt >= fromUtc && u.CreatedAt < toUtc, ct);
        var lowStock = await db.ProductVariants.CountAsync(v => v.IsActive && v.StockQuantity <= settings.Settings.LowStockThreshold, ct);
        var placedPerDay = (await orders.Select(o => o.CreatedAt).ToListAsync(ct))
            .GroupBy(settings.ToLocalDate).ToDictionary(g => g.Key, g => g.Count());
        var revenuePerDay = paid.GroupBy(p => settings.ToLocalDate(p.CreatedAt)).ToDictionary(g => g.Key, g => g.Sum(p => p.TotalAmount));

        var daily = new List<DailyRevenueDto>();
        for (var day = from; day <= to; day = day.AddDays(1))
            daily.Add(new DailyRevenueDto(day, placedPerDay.GetValueOrDefault(day), revenuePerDay.GetValueOrDefault(day)));

        var totalOrders = byStatus.Sum(s => s.Count);
        var revenue = paid.Sum(p => p.TotalAmount);
        return new DashboardSummaryDto(
            from, to, totalOrders, paid.Count, revenue, paid.Count == 0 ? 0 : Math.Round(revenue / paid.Count, 0),
            newCustomers, byStatus.SingleOrDefault(s => s.Status == OrderStatus.Cancelled)?.Count ?? 0, lowStock,
            Enum.GetValues<OrderStatus>().Select(s => new StatusCountDto(s, byStatus.SingleOrDefault(x => x.Status == s)?.Count ?? 0)).ToList(),
            daily, RevenueDefinition);
    }

    // UC-077
    public async Task<OrderReportDto> GetOrderReportAsync(OrderReportQuery q, CancellationToken ct)
    {
        var (from, to, fromUtc, toUtc) = settings.ResolveReportRange(q.From, q.To);
        var orders = OrdersIn(fromUtc, toUtc);
        if (q.Status is not null) orders = orders.Where(o => o.Status == q.Status);

        var data = await orders.Select(o => new
        {
            o.CreatedAt, o.Status, o.TotalAmount,
            Paid = o.Status != OrderStatus.Cancelled && o.Payment != null && o.Payment.Status == PaymentStatus.Paid,
        }).ToListAsync(ct);

        var groupBy = string.Equals(q.GroupBy, "status", StringComparison.OrdinalIgnoreCase) ? "status" : "day";
        List<OrderReportRowDto> rows;
        if (groupBy == "status")
        {
            rows = Enum.GetValues<OrderStatus>().Select(s =>
            {
                var group = data.Where(d => d.Status == s).ToList();
                return new OrderReportRowDto(s.ToString(), group.Count, group.Sum(d => d.TotalAmount), group.Where(d => d.Paid).Sum(d => d.TotalAmount));
            }).Where(r => q.Status is null || r.Group == q.Status.ToString()).ToList();
        }
        else
        {
            var byDay = data.GroupBy(d => settings.ToLocalDate(d.CreatedAt)).ToDictionary(g => g.Key, g => g.ToList());
            rows = [];
            for (var day = from; day <= to; day = day.AddDays(1))
            {
                var group = byDay.GetValueOrDefault(day) ?? [];
                rows.Add(new OrderReportRowDto(day.ToString("yyyy-MM-dd"), group.Count, group.Sum(d => d.TotalAmount), group.Where(d => d.Paid).Sum(d => d.TotalAmount)));
            }
        }

        return new OrderReportDto(from, to, groupBy, rows, data.Count, data.Sum(d => d.TotalAmount));
    }

    // UC-078
    public async Task<TopProductsReportDto> GetTopProductsAsync(TopProductsQuery q, CancellationToken ct)
    {
        var (from, to, fromUtc, toUtc) = settings.ResolveReportRange(q.From, q.To);
        var qualifying = Revenue(OrdersIn(fromUtc, toUtc)).Select(o => o.Id);

        var top = await db.OrderItems.AsNoTracking()
            .Where(i => qualifying.Contains(i.OrderId))
            .GroupBy(i => i.ProductId)
            .Select(g => new { ProductId = g.Key, Quantity = g.Sum(i => i.Quantity), Revenue = g.Sum(i => i.LineTotal) })
            .OrderByDescending(x => x.Quantity).ThenByDescending(x => x.Revenue).ThenBy(x => x.ProductId)
            .Take(q.Limit)
            .ToListAsync(ct);

        var ids = top.Select(t => t.ProductId).ToList();
        var products = await db.Products.AsNoTracking().Where(p => ids.Contains(p.Id))
            .Select(p => new
            {
                p.Id, p.Name,
                ImageUrl = p.Images.OrderByDescending(i => i.IsPrimary).ThenBy(i => i.DisplayOrder).Select(i => i.Url).FirstOrDefault(),
            })
            .ToDictionaryAsync(p => p.Id, ct);

        var rows = top.Select((t, index) => new TopProductDto(index + 1, t.ProductId, products[t.ProductId].Name,
            products[t.ProductId].ImageUrl, t.Quantity, t.Revenue)).ToList();
        return new TopProductsReportDto(from, to, rows, BestSellingDefinition);
    }
}
