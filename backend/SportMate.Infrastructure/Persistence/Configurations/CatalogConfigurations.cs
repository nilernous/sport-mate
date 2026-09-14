using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Infrastructure.Persistence.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> b)
    {
        b.Property(x => x.Name).HasMaxLength(100).IsRequired();
        b.HasIndex(x => x.Name).IsUnique();
        b.Property(x => x.Description).HasMaxLength(500);
    }
}

public class BrandConfiguration : IEntityTypeConfiguration<Brand>
{
    public void Configure(EntityTypeBuilder<Brand> b)
    {
        b.Property(x => x.Name).HasMaxLength(100).IsRequired();
        b.HasIndex(x => x.Name).IsUnique();
        b.Property(x => x.Description).HasMaxLength(500);
        b.Property(x => x.LogoUrl).HasMaxLength(500);
    }
}

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> b)
    {
        b.Property(x => x.Name).HasMaxLength(200).IsRequired();
        b.Property(x => x.Description).HasMaxLength(4000);
        b.HasIndex(x => x.Name);
        b.HasIndex(x => x.IsActive);
        b.ToTable(t => t.HasCheckConstraint("CK_Products_BasePrice", "[BasePrice] >= 0"));
        // Restrict: a referenced category/brand cannot be physically deleted (BR-015).
        b.HasOne(x => x.Category).WithMany(c => c.Products).HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
        b.HasOne(x => x.Brand).WithMany(c => c.Products).HasForeignKey(x => x.BrandId).OnDelete(DeleteBehavior.Restrict);
    }
}

public class ProductVariantConfiguration : IEntityTypeConfiguration<ProductVariant>
{
    public void Configure(EntityTypeBuilder<ProductVariant> b)
    {
        b.Property(x => x.Sku).HasMaxLength(64).IsRequired();
        b.HasIndex(x => x.Sku).IsUnique();
        b.Property(x => x.Size).HasMaxLength(20).IsRequired();
        b.Property(x => x.Color).HasMaxLength(50).IsRequired();
        b.ToTable(t =>
        {
            t.HasCheckConstraint("CK_ProductVariants_Price", "[Price] >= 0");
            t.HasCheckConstraint("CK_ProductVariants_Stock", "[StockQuantity] >= 0");
        });
        b.HasOne(x => x.Product).WithMany(p => p.Variants).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class ProductImageConfiguration : IEntityTypeConfiguration<ProductImage>
{
    public void Configure(EntityTypeBuilder<ProductImage> b)
    {
        b.Property(x => x.Url).HasMaxLength(500).IsRequired();
        b.Property(x => x.AltText).HasMaxLength(200);
        b.HasOne(x => x.Product).WithMany(p => p.Images).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class StockMovementConfiguration : IEntityTypeConfiguration<StockMovement>
{
    public void Configure(EntityTypeBuilder<StockMovement> b)
    {
        b.Property(x => x.Reason).HasMaxLength(500);
        b.HasIndex(x => new { x.VariantId, x.CreatedAt });
        b.HasOne(x => x.Variant).WithMany().HasForeignKey(x => x.VariantId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne(x => x.ActorUser).WithMany().HasForeignKey(x => x.ActorUserId).OnDelete(DeleteBehavior.Restrict);
    }
}
