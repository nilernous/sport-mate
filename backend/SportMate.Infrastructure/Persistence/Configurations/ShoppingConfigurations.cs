using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Infrastructure.Persistence.Configurations;

public class CartConfiguration : IEntityTypeConfiguration<Cart>
{
    public void Configure(EntityTypeBuilder<Cart> b)
    {
        b.HasIndex(x => x.UserId).IsUnique();
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class CartItemConfiguration : IEntityTypeConfiguration<CartItem>
{
    public void Configure(EntityTypeBuilder<CartItem> b)
    {
        b.HasIndex(x => new { x.CartId, x.VariantId }).IsUnique();
        b.ToTable(t => t.HasCheckConstraint("CK_CartItems_Quantity", "[Quantity] > 0"));
        b.HasOne(x => x.Cart).WithMany(c => c.Items).HasForeignKey(x => x.CartId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.Variant).WithMany().HasForeignKey(x => x.VariantId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class WishlistItemConfiguration : IEntityTypeConfiguration<WishlistItem>
{
    public void Configure(EntityTypeBuilder<WishlistItem> b)
    {
        b.HasIndex(x => new { x.UserId, x.ProductId }).IsUnique();
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.Product).WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> b)
    {
        b.Property(x => x.Comment).HasMaxLength(1000);
        // One review per customer per product (BR-063).
        b.HasIndex(x => new { x.ProductId, x.UserId }).IsUnique();
        b.ToTable(t => t.HasCheckConstraint("CK_Reviews_Rating", "[Rating] BETWEEN 1 AND 5"));
        b.HasOne(x => x.Product).WithMany(p => p.Reviews).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class CouponConfiguration : IEntityTypeConfiguration<Coupon>
{
    public void Configure(EntityTypeBuilder<Coupon> b)
    {
        b.Property(x => x.Code).HasMaxLength(50).IsRequired();
        b.HasIndex(x => x.Code).IsUnique();
        b.Property(x => x.Description).HasMaxLength(500);
        b.ToTable(t =>
        {
            t.HasCheckConstraint("CK_Coupons_DiscountValue", "[DiscountValue] > 0");
            t.HasCheckConstraint("CK_Coupons_MinOrderAmount", "[MinOrderAmount] >= 0");
            t.HasCheckConstraint("CK_Coupons_Window", "[EndsAt] > [StartsAt]");
        });
        b.HasOne(x => x.ApplicableCategory).WithMany().HasForeignKey(x => x.ApplicableCategoryId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class CouponUsageConfiguration : IEntityTypeConfiguration<CouponUsage>
{
    public void Configure(EntityTypeBuilder<CouponUsage> b)
    {
        b.HasIndex(x => new { x.CouponId, x.UserId });
        b.HasIndex(x => x.OrderId).IsUnique();
        b.HasOne(x => x.Coupon).WithMany().HasForeignKey(x => x.CouponId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<User>().WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<Order>().WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
    }
}
