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
}
