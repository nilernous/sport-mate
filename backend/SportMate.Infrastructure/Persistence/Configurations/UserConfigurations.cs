using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> b)
    {
        b.Property(x => x.FullName).HasMaxLength(100).IsRequired();
        b.Property(x => x.Email).HasMaxLength(256).IsRequired();
        b.Property(x => x.NormalizedEmail).HasMaxLength(256).IsRequired();
        b.HasIndex(x => x.NormalizedEmail).IsUnique();
        b.Property(x => x.PasswordHash).HasMaxLength(512).IsRequired();
        b.Property(x => x.PhoneNumber).HasMaxLength(20);
        b.HasIndex(x => x.Role);
    }
}

public class PasswordResetTokenConfiguration : IEntityTypeConfiguration<PasswordResetToken>
{
    public void Configure(EntityTypeBuilder<PasswordResetToken> b)
    {
        b.Property(x => x.TokenHash).HasMaxLength(128).IsRequired();
        b.HasIndex(x => x.TokenHash).IsUnique();
        b.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

public class UserAddressConfiguration : IEntityTypeConfiguration<UserAddress>
{
    public void Configure(EntityTypeBuilder<UserAddress> b)
    {
        b.Property(x => x.RecipientName).HasMaxLength(100).IsRequired();
        b.Property(x => x.PhoneNumber).HasMaxLength(20).IsRequired();
        b.Property(x => x.AddressLine).HasMaxLength(255).IsRequired();
        b.Property(x => x.Ward).HasMaxLength(100).IsRequired();
        b.Property(x => x.District).HasMaxLength(100).IsRequired();
        b.Property(x => x.City).HasMaxLength(100).IsRequired();
        b.HasOne(x => x.User).WithMany(u => u.Addresses).HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
