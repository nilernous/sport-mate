using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> b)
    {
        b.Property(x => x.OrderCode).HasMaxLength(32).IsRequired();
        b.HasIndex(x => x.OrderCode).IsUnique();
        b.Property(x => x.CouponCode).HasMaxLength(50);
        b.Property(x => x.RecipientName).HasMaxLength(100).IsRequired();
        b.Property(x => x.PhoneNumber).HasMaxLength(20).IsRequired();
        b.Property(x => x.AddressLine).HasMaxLength(255).IsRequired();
        b.Property(x => x.Ward).HasMaxLength(100).IsRequired();
        b.Property(x => x.District).HasMaxLength(100).IsRequired();
        b.Property(x => x.City).HasMaxLength(100).IsRequired();
        b.Property(x => x.Note).HasMaxLength(500);
        b.Property(x => x.IdempotencyKey).HasMaxLength(64);
        // Duplicate-submission guard (BR-036).
        b.HasIndex(x => new { x.UserId, x.IdempotencyKey }).IsUnique().HasFilter("[IdempotencyKey] IS NOT NULL");
        b.HasIndex(x => new { x.Status, x.CreatedAt });
        b.Property(x => x.RowVersion).IsRowVersion();
        b.ToTable(t => t.HasCheckConstraint("CK_Orders_Total", "[TotalAmount] >= 0"));
        // Orders are never hard-deleted with their user (BR-044).
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<Coupon>().WithMany().HasForeignKey(x => x.CouponId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> b)
    {
        b.Property(x => x.ProductName).HasMaxLength(200).IsRequired();
        b.Property(x => x.Sku).HasMaxLength(64).IsRequired();
        b.Property(x => x.Size).HasMaxLength(20).IsRequired();
        b.Property(x => x.Color).HasMaxLength(50).IsRequired();
        b.Property(x => x.ImageUrl).HasMaxLength(500);
        b.HasIndex(x => x.ProductId);
        b.HasIndex(x => x.VariantId);
        b.ToTable(t => t.HasCheckConstraint("CK_OrderItems_Quantity", "[Quantity] > 0"));
        b.HasOne(x => x.Order).WithMany(o => o.Items).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        // Product/variant FKs are intentionally Restrict so referenced catalog rows are archived, not deleted (BR-020).
        b.HasOne<Product>().WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne<ProductVariant>().WithMany().HasForeignKey(x => x.VariantId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class OrderStatusHistoryConfiguration : IEntityTypeConfiguration<OrderStatusHistory>
{
    public void Configure(EntityTypeBuilder<OrderStatusHistory> b)
    {
        b.Property(x => x.Note).HasMaxLength(500);
        b.HasOne(x => x.Order).WithMany(o => o.StatusHistory).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.ChangedByUser).WithMany().HasForeignKey(x => x.ChangedByUserId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
{
    public void Configure(EntityTypeBuilder<Payment> b)
    {
        b.HasIndex(x => x.OrderId).IsUnique();
        b.Property(x => x.TransferReference).HasMaxLength(100);
        b.Property(x => x.Note).HasMaxLength(500);
        b.Property(x => x.RowVersion).IsRowVersion();
        b.HasOne(x => x.Order).WithOne(o => o.Payment).HasForeignKey<Payment>(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.ConfirmedByUser).WithMany().HasForeignKey(x => x.ConfirmedByUserId).OnDelete(DeleteBehavior.Restrict);
    }
}
