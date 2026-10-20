using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Application.Mappings;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Coupon administration (UC-061 – UC-064) and coupon evaluation (UC-065 – UC-067).</summary>
public class CouponService(IApplicationDbContext db)
{
    /// <summary>A cart line as seen by coupon evaluation.</summary>
    public record PricedLine(int ProductId, int CategoryId, decimal LineTotal);

    public record Evaluation(Coupon? Coupon, bool IsValid, decimal DiscountAmount, string Message)
    {
        public CouponCheckDto ToDto(string code) => new(IsValid, Coupon?.Code ?? TextNormalizer.Key(code), DiscountAmount, Message);
    }

    // ---------- Admin ----------

    // UC-062
    public async Task<PagedResult<CouponDto>> ListAsync(CouponQuery q, CancellationToken ct)
    {
        var query = db.Coupons.AsNoTracking().Include(c => c.ApplicableCategory).AsQueryable();
        if (!string.IsNullOrWhiteSpace(q.Keyword))
        {
            var k = q.Keyword.Trim();
            query = query.Where(c => c.Code.Contains(k) || (c.Description != null && c.Description.Contains(k)));
        }
        if (q.IsActive is not null) query = query.Where(c => c.IsActive == q.IsActive);

        var page = await query.OrderByDescending(c => c.CreatedAt).ToPagedResultAsync(q, ct);
        return new PagedResult<CouponDto>(page.Items.Select(c => c.ToDto()).ToList(), page.Page, page.PageSize, page.TotalItems, page.TotalPages);
    }

    // UC-062
    public async Task<CouponDto> GetAsync(int id, CancellationToken ct) =>
        (await db.Coupons.AsNoTracking().Include(c => c.ApplicableCategory).SingleOrDefaultAsync(c => c.Id == id, ct)
         ?? throw AppException.NotFound("Coupon")).ToDto();

    // UC-061
    public async Task<CouponDto> CreateAsync(CouponRequest r, CancellationToken ct)
    {
        var code = TextNormalizer.Key(r.Code);
        await ValidateAsync(r, code, null, ct);
        var now = DateTime.UtcNow;
        var coupon = new Coupon { Code = code, CreatedAt = now };
        Apply(coupon, r, now);
        db.Coupons.Add(coupon);
        await db.SaveChangesAsync(ct);
        return await GetAsync(coupon.Id, ct);
    }

    // UC-063: orders store their own discount, so edits never change past totals (BR-060).
    public async Task<CouponDto> UpdateAsync(int id, CouponRequest r, CancellationToken ct)
    {
        var coupon = await db.Coupons.FindAsync([id], ct) ?? throw AppException.NotFound("Coupon");
        var code = TextNormalizer.Key(r.Code);
        await ValidateAsync(r, code, id, ct);
        if (r.UsageLimit is not null && r.UsageLimit < coupon.UsedCount)
            throw AppException.BadRequest($"Usage limit cannot be lower than the {coupon.UsedCount} uses already recorded.", "usageLimit");
        if (code != coupon.Code && coupon.UsedCount > 0)
            throw AppException.Conflict("The code of a coupon that has already been used cannot be changed.");

        coupon.Code = code;
        Apply(coupon, r, DateTime.UtcNow);
        await db.SaveChangesAsync(ct);
        return await GetAsync(id, ct);
    }

    // UC-064
    public async Task<DeleteResultDto> DeleteAsync(int id, CancellationToken ct)
    {
        var coupon = await db.Coupons.FindAsync([id], ct) ?? throw AppException.NotFound("Coupon");
        var used = await db.CouponUsages.AnyAsync(u => u.CouponId == id, ct) || await db.Orders.AnyAsync(o => o.CouponId == id, ct);
        if (used)
        {
            coupon.IsActive = false;
            coupon.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            return DeleteResultDto.Deactivated("Coupon", "existing orders");
        }

        db.Coupons.Remove(coupon);
        await db.SaveChangesAsync(ct);
        return DeleteResultDto.Deleted("Coupon");
    }

    private async Task ValidateAsync(CouponRequest r, string code, int? exceptId, CancellationToken ct)
    {
        if (r.EndsAt <= r.StartsAt) throw AppException.BadRequest("endsAt must be after startsAt.", "endsAt");
        if (r.DiscountType == DiscountType.Percentage && r.DiscountValue > 100)
            throw AppException.BadRequest("A percentage discount cannot exceed 100.", "discountValue");
        if (r.DiscountType == DiscountType.FixedAmount && r.MaxDiscountAmount is not null)
            throw AppException.BadRequest("maxDiscountAmount only applies to percentage coupons.", "maxDiscountAmount");
        if (r.PerUserLimit is not null && r.UsageLimit is not null && r.PerUserLimit > r.UsageLimit)
            throw AppException.BadRequest("perUserLimit cannot exceed usageLimit.", "perUserLimit");
        if (r.ApplicableCategoryId is not null && !await db.Categories.AnyAsync(c => c.Id == r.ApplicableCategoryId, ct))
            throw AppException.BadRequest("Category does not exist.", "applicableCategoryId");
        if (await db.Coupons.AnyAsync(c => c.Code == code && c.Id != exceptId, ct))
            throw AppException.Conflict($"Coupon code '{code}' already exists.");
    }

    private static void Apply(Coupon c, CouponRequest r, DateTime now)
    {
        c.Description = TextNormalizer.Clean(r.Description);
        c.DiscountType = r.DiscountType!.Value;
        c.DiscountValue = r.DiscountValue;
        c.MaxDiscountAmount = r.MaxDiscountAmount;
        c.MinOrderAmount = r.MinOrderAmount;
        c.ApplicableCategoryId = r.ApplicableCategoryId;
        c.StartsAt = DateTimeUtc.ToUtc(r.StartsAt);
        c.EndsAt = DateTimeUtc.ToUtc(r.EndsAt);
        c.UsageLimit = r.UsageLimit;
        c.PerUserLimit = r.PerUserLimit;
        c.IsActive = r.IsActive;
        c.UpdatedAt = now;
    }

    // ---------- Evaluation ----------

    /// <summary>
    /// Checks every coupon rule against the given lines (BR-055 – BR-057). Pure read:
    /// it never consumes usage (BR-059).
    /// </summary>
    public async Task<Evaluation> EvaluateAsync(string rawCode, int userId, IReadOnlyCollection<PricedLine> lines, CancellationToken ct)
    {
        var code = TextNormalizer.Key(rawCode);
        var coupon = await db.Coupons.AsNoTracking().SingleOrDefaultAsync(c => c.Code == code, ct);
        if (coupon is null) return Invalid(null, "Coupon code does not exist.");
        if (!coupon.IsActive) return Invalid(coupon, "This coupon is no longer available.");

        var now = DateTime.UtcNow;
        if (now < coupon.StartsAt) return Invalid(coupon, "This coupon is not active yet.");
        if (now >= coupon.EndsAt) return Invalid(coupon, "This coupon has expired.");
        if (coupon.UsageLimit is not null && coupon.UsedCount >= coupon.UsageLimit)
            return Invalid(coupon, "This coupon has reached its usage limit.");
        if (coupon.PerUserLimit is not null)
        {
            var usedByUser = await db.CouponUsages.CountAsync(u => u.CouponId == coupon.Id && u.UserId == userId, ct);
            if (usedByUser >= coupon.PerUserLimit) return Invalid(coupon, "You have already used this coupon the maximum number of times.");
        }

        if (lines.Count == 0) return Invalid(coupon, "Your cart is empty.");
        var subtotal = lines.Sum(l => l.LineTotal);
        if (subtotal < coupon.MinOrderAmount)
            return Invalid(coupon, $"Minimum order value for this coupon is {coupon.MinOrderAmount:N0} VND.");

        var eligible = coupon.ApplicableCategoryId is null
            ? subtotal
            : lines.Where(l => l.CategoryId == coupon.ApplicableCategoryId).Sum(l => l.LineTotal);
        if (eligible <= 0) return Invalid(coupon, "No items in your cart are eligible for this coupon.");

        var discount = coupon.DiscountType == DiscountType.Percentage
            ? Math.Round(eligible * coupon.DiscountValue / 100m, 0, MidpointRounding.AwayFromZero)
            : coupon.DiscountValue;
        if (coupon.MaxDiscountAmount is not null) discount = Math.Min(discount, coupon.MaxDiscountAmount.Value);
        // A discount can never exceed what it applies to, so totals never go negative (BR-057).
        discount = Math.Min(discount, eligible);

        return new Evaluation(coupon, true, discount, $"Coupon applied: -{discount:N0} VND.");
    }

    private static Evaluation Invalid(Coupon? coupon, string message) => new(coupon, false, 0, message);
}
