using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>Product reviews (UC-068 – UC-072).</summary>
public class ReviewService(IApplicationDbContext db)
{
    // UC-069: public listing shows approved reviews only (BR-065).
    public async Task<ProductReviewsDto> ListForProductAsync(int productId, PageQuery q, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId && p.IsActive, ct)) throw AppException.NotFound("Product");

        var approved = db.Reviews.AsNoTracking().Where(r => r.ProductId == productId && r.Status == ReviewStatus.Approved);
        var counts = await approved.GroupBy(r => r.Rating).Select(g => new { Rating = g.Key, Count = g.Count() }).ToListAsync(ct);
        var total = counts.Sum(c => c.Count);
        var average = total == 0 ? 0 : Math.Round(counts.Sum(c => c.Rating * c.Count) / (double)total, 1);
        var ratingCounts = Enumerable.Range(1, 5).ToDictionary(r => r, r => counts.SingleOrDefault(c => c.Rating == r)?.Count ?? 0);

        var page = await Project(approved.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id)).ToPagedResultAsync(q, ct);
        return new ProductReviewsDto(new ReviewSummaryDto(average, total, ratingCounts), page);
    }

    // UC-069 (Staff/Admin view, any status)
    public async Task<PagedResult<ReviewDto>> ListForModerationAsync(AdminReviewQuery q, CancellationToken ct)
    {
        var query = db.Reviews.AsNoTracking();
        if (q.Status is not null) query = query.Where(r => r.Status == q.Status);
        if (q.ProductId is not null) query = query.Where(r => r.ProductId == q.ProductId);
        return await Project(query.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id)).ToPagedResultAsync(q, ct);
    }

    /// <summary>Tells the app whether to show "write a review" or the customer's existing review.</summary>
    public async Task<MyReviewStatusDto> GetMyStatusAsync(int userId, int productId, CancellationToken ct)
    {
        var review = await Project(db.Reviews.AsNoTracking().Where(r => r.ProductId == productId && r.UserId == userId)).SingleOrDefaultAsync(ct);
        if (review is not null) return new MyReviewStatusDto(false, "You have already reviewed this product.", review);

        return await HasCompletedPurchaseAsync(userId, productId, ct)
            ? new MyReviewStatusDto(true, null, null)
            : new MyReviewStatusDto(false, "You can review this product after an order containing it is completed.", null);
    }

    // UC-068: requires a completed order containing the product (BR-061), one review per product (BR-063).
    public async Task<ReviewDto> CreateAsync(int userId, int productId, ReviewRequest r, CancellationToken ct)
    {
        if (!await db.Products.AnyAsync(p => p.Id == productId, ct)) throw AppException.NotFound("Product");
        if (await db.Reviews.AnyAsync(x => x.ProductId == productId && x.UserId == userId, ct))
            throw AppException.Conflict("You have already reviewed this product. Edit your existing review instead.");
        if (!await HasCompletedPurchaseAsync(userId, productId, ct))
            throw AppException.Forbidden("You can review this product after an order containing it is completed.");

        var now = DateTime.UtcNow;
        var review = new Review
        {
            ProductId = productId, UserId = userId, Rating = r.Rating, Comment = TextNormalizer.Clean(r.Comment),
            Status = ReviewStatus.Approved, CreatedAt = now, UpdatedAt = now,
        };
        db.Reviews.Add(review);
        await db.SaveChangesAsync(ct);
        return await GetAsync(review.Id, ct);
    }

    // UC-070
    public async Task<ReviewDto> UpdateOwnAsync(int userId, int reviewId, ReviewRequest r, CancellationToken ct)
    {
        var review = await db.Reviews.SingleOrDefaultAsync(x => x.Id == reviewId && x.UserId == userId, ct)
                     ?? throw AppException.NotFound("Review");
        if (review.Status == ReviewStatus.Rejected)
            throw AppException.Conflict("A rejected review cannot be edited.");

        review.Rating = r.Rating;
        review.Comment = TextNormalizer.Clean(r.Comment);
        review.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetAsync(reviewId, ct);
    }

    // UC-071: owners delete their own review; Staff/Admin may remove any review.
    public async Task DeleteAsync(int userId, bool isStaff, int reviewId, CancellationToken ct)
    {
        var review = await db.Reviews.SingleOrDefaultAsync(x => x.Id == reviewId && (isStaff || x.UserId == userId), ct)
                     ?? throw AppException.NotFound("Review");
        db.Reviews.Remove(review);
        await db.SaveChangesAsync(ct);
    }

    // UC-072
    public async Task<ReviewDto> ModerateAsync(int actorId, int reviewId, ReviewStatus status, CancellationToken ct)
    {
        var review = await db.Reviews.FindAsync([reviewId], ct) ?? throw AppException.NotFound("Review");
        review.Status = status;
        review.ModeratedByUserId = actorId;
        review.ModeratedAt = DateTime.UtcNow;
        review.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await GetAsync(reviewId, ct);
    }

    private Task<bool> HasCompletedPurchaseAsync(int userId, int productId, CancellationToken ct) =>
        db.OrderItems.AnyAsync(i => i.ProductId == productId && i.Order.UserId == userId && i.Order.Status == OrderStatus.Completed, ct);

    private async Task<ReviewDto> GetAsync(int id, CancellationToken ct) =>
        await Project(db.Reviews.AsNoTracking().Where(r => r.Id == id)).SingleAsync(ct);

    private static IQueryable<ReviewDto> Project(IQueryable<Review> query) =>
        query.Select(r => new ReviewDto(r.Id, r.ProductId, r.Product.Name, r.UserId, r.User.FullName, r.Rating, r.Comment, r.Status, r.CreatedAt, r.UpdatedAt));
}
