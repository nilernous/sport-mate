using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Infrastructure.Persistence;

/// <summary>
/// Development only: applies migrations and, on an empty database, inserts demo accounts,
/// catalog, coupons and a few orders so every screen has data to show.
/// </summary>
public class DataSeeder(ApplicationDbContext db, IPasswordHasher hasher, IConfiguration config, ILogger<DataSeeder> logger)
{
    public async Task MigrateAndSeedAsync()
    {
        await db.Database.MigrateAsync();
        if (!config.GetValue("Seed:Enabled", false) || await db.Users.AnyAsync()) return;

        logger.LogInformation("Seeding demo data...");
        var now = DateTime.UtcNow;

        // ---------- Users ----------
        var admin = NewUser("Sport Mate Admin", "admin@sportmate.vn", UserRole.Admin, config["Seed:AdminPassword"]!, now.AddDays(-90));
        var staff = NewUser("Tran Thi Staff", "staff@sportmate.vn", UserRole.Staff, config["Seed:StaffPassword"]!, now.AddDays(-80));
        var customer = NewUser("Nguyen Van Khach", "customer@sportmate.vn", UserRole.Customer, config["Seed:CustomerPassword"]!, now.AddDays(-60));
        customer.PhoneNumber = "0901234567";
        db.Users.AddRange(admin, staff, customer);

        var address = new UserAddress
        {
            User = customer, RecipientName = "Nguyen Van Khach", PhoneNumber = "0901234567",
            AddressLine = "123 Nguyen Hue", Ward = "Ben Nghe", District = "District 1", City = "Ho Chi Minh City",
            IsDefault = true, CreatedAt = now, UpdatedAt = now,
        };
        db.UserAddresses.Add(address);

        // ---------- Catalog ----------
        Category Cat(string name, string description) => new() { Name = name, Description = description, CreatedAt = now, UpdatedAt = now };
        Brand Brand(string name) => new() { Name = name, CreatedAt = now, UpdatedAt = now };

        var running = Cat("Running Shoes", "Lightweight shoes for road and trail running.");
        var football = Cat("Football", "Boots, balls and gear for the pitch.");
        var training = Cat("Gym & Training", "Apparel and equipment for the gym.");
        var basketball = Cat("Basketball", "Shoes and balls for the court.");
        var apparel = Cat("Sportswear", "Shirts, shorts and jackets for every sport.");
        var accessories = Cat("Accessories", "Bags, bottles, socks and more.");
        db.Categories.AddRange(running, football, training, basketball, apparel, accessories);

        var nike = Brand("Nike");
        var adidas = Brand("Adidas");
        var puma = Brand("Puma");
        var underArmour = Brand("Under Armour");
        var asics = Brand("Asics");
        var mizuno = Brand("Mizuno");
        db.Brands.AddRange(nike, adidas, puma, underArmour, asics, mizuno);

        var shoeSizes = new[] { "39", "40", "41", "42", "43" };
        var apparelSizes = new[] { "S", "M", "L", "XL" };
        var products = new List<Product>();
        var skuCounter = 0;

        Product AddProduct(string name, string description, Category category, Brand brand, decimal price,
            string[] colors, string[] sizes, int stock, int daysAgo)
        {
            var created = now.AddDays(-daysAgo);
            var product = new Product
            {
                Name = name, Description = description, Category = category, Brand = brand, BasePrice = price,
                CreatedAt = created, UpdatedAt = created,
            };
            var index = products.Count + 1;
            for (var i = 0; i < 3; i++)
            {
                product.Images.Add(new ProductImage
                {
                    Url = $"https://picsum.photos/seed/sportmate-{index}-{i}/800/800",
                    AltText = $"{name} image {i + 1}", DisplayOrder = i, IsPrimary = i == 0, CreatedAt = created,
                });
            }
            foreach (var color in colors)
            {
                foreach (var size in sizes)
                {
                    skuCounter++;
                    // A few options are low or out of stock so the inventory screens have something to show.
                    var qty = skuCounter % 11 == 0 ? 0 : skuCounter % 7 == 0 ? 3 : stock;
                    product.Variants.Add(new ProductVariant
                    {
                        Sku = TextNormalizer.Key($"SM-{index:D3}-{color[..Math.Min(3, color.Length)]}-{size}"),
                        Size = size, Color = color, Price = price, StockQuantity = qty, CreatedAt = created, UpdatedAt = created,
                    });
                }
            }
            products.Add(product);
            db.Products.Add(product);
            return product;
        }

        var pegasus = AddProduct("Nike Air Zoom Pegasus 41", "Responsive daily trainer with ReactX foam and Zoom Air units.", running, nike, 3_519_000m, ["Black", "White"], shoeSizes, 15, 50);
        AddProduct("Adidas Ultraboost Light", "Lightest Ultraboost ever with energy-returning Light BOOST.", running, adidas, 4_200_000m, ["Core Black", "Cloud White"], shoeSizes, 10, 45);
        var novablast = AddProduct("Asics Novablast 4", "Bouncy FF Blast+ cushioning for tempo and long runs.", running, asics, 3_290_000m, ["Blue", "Orange"], shoeSizes, 12, 40);
        AddProduct("Puma Velocity Nitro 3", "Nitro foam trainer built for everyday miles.", running, puma, 2_890_000m, ["Black"], shoeSizes, 8, 20);
        AddProduct("Nike Mercurial Vapor 16 Academy", "Firm-ground boots for explosive speed.", football, nike, 2_349_000m, ["Volt", "Black"], shoeSizes, 9, 38);
        AddProduct("Adidas Predator League FG", "Grippy strike zone for control in every touch.", football, adidas, 2_100_000m, ["Black", "Red"], shoeSizes, 9, 35);
        AddProduct("Mizuno Morelia Neo IV Pro", "Kangaroo-leather feel, made for touch and fit.", football, mizuno, 3_600_000m, ["White"], shoeSizes, 6, 25);
        AddProduct("Adidas UCL League Ball", "Official match ball replica, size 5.", football, adidas, 750_000m, ["White"], ["5"], 30, 30);
        var tee = AddProduct("Under Armour Tech 2.0 T-Shirt", "Quick-drying, ultra-soft training tee.", training, underArmour, 650_000m, ["Black", "Grey", "Navy"], apparelSizes, 25, 33);
        AddProduct("Nike Dri-FIT Challenger Shorts", "7-inch running shorts with built-in briefs.", training, nike, 890_000m, ["Black", "Blue"], apparelSizes, 20, 28);
        AddProduct("Puma Train Fav Hoodie", "Soft fleece hoodie for warm-ups and cool-downs.", training, puma, 1_250_000m, ["Black", "Grey"], apparelSizes, 15, 15);
        AddProduct("Nike LeBron Witness 8", "Supportive basketball shoe with Air Zoom cushioning.", basketball, nike, 2_929_000m, ["White", "Black"], shoeSizes, 7, 22);
        AddProduct("Adidas All Court 3.0 Basketball", "Durable indoor/outdoor composite basketball, size 7.", basketball, adidas, 1_150_000m, ["Orange"], ["7"], 18, 18);
        AddProduct("Adidas Own The Run Jacket", "Wind-resistant running jacket with reflective details.", apparel, adidas, 1_600_000m, ["Black", "Green"], apparelSizes, 12, 12);
        AddProduct("Under Armour Undeniable Duffle 4.0", "Water-resistant gym bag, 58 L.", accessories, underArmour, 1_390_000m, ["Black"], ["One Size"], 20, 10);
        AddProduct("Nike Everyday Cushioned Socks (3 pairs)", "Cushioned crew socks with Dri-FIT technology.", accessories, nike, 390_000m, ["White", "Black"], ["M", "L"], 40, 5);

        // ---------- Coupons ----------
        db.Coupons.AddRange(
            new Coupon
            {
                Code = "WELCOME10", Description = "10% off your order (max 200,000 VND) for orders from 500,000 VND.",
                DiscountType = DiscountType.Percentage, DiscountValue = 10, MaxDiscountAmount = 200_000, MinOrderAmount = 500_000,
                StartsAt = now.AddDays(-30), EndsAt = now.AddDays(180), PerUserLimit = 1, IsActive = true, CreatedAt = now, UpdatedAt = now,
            },
            new Coupon
            {
                Code = "SALE50K", Description = "50,000 VND off orders from 1,000,000 VND.",
                DiscountType = DiscountType.FixedAmount, DiscountValue = 50_000, MinOrderAmount = 1_000_000,
                StartsAt = now.AddDays(-7), EndsAt = now.AddDays(60), UsageLimit = 100, IsActive = true, CreatedAt = now, UpdatedAt = now,
            },
            new Coupon
            {
                Code = "RUN15", Description = "15% off running shoes.", DiscountType = DiscountType.Percentage, DiscountValue = 15,
                MaxDiscountAmount = 500_000, MinOrderAmount = 0, ApplicableCategory = running,
                StartsAt = now.AddDays(-1), EndsAt = now.AddDays(30), UsageLimit = 50, PerUserLimit = 2, IsActive = true, CreatedAt = now, UpdatedAt = now,
            },
            new Coupon
            {
                Code = "EXPIRED20", Description = "Expired demo coupon.", DiscountType = DiscountType.Percentage, DiscountValue = 20,
                MinOrderAmount = 0, StartsAt = now.AddDays(-60), EndsAt = now.AddDays(-30), IsActive = true, CreatedAt = now, UpdatedAt = now,
            });

        await db.SaveChangesAsync();

        // ---------- Demo orders ----------
        Order AddOrder(string code, OrderStatus status, PaymentMethod method, PaymentStatus paymentStatus, int daysAgo,
            params (Product Product, int VariantIndex, int Quantity)[] lines)
        {
            var created = now.AddDays(-daysAgo);
            var items = lines.Select(l =>
            {
                var v = l.Product.Variants[l.VariantIndex];
                return new OrderItem
                {
                    ProductId = l.Product.Id, VariantId = v.Id, ProductName = l.Product.Name, Sku = v.Sku, Size = v.Size,
                    Color = v.Color, ImageUrl = l.Product.Images[0].Url, UnitPrice = v.Price, Quantity = l.Quantity,
                    LineTotal = v.Price * l.Quantity,
                };
            }).ToList();
            var subtotal = items.Sum(i => i.LineTotal);
            var shipping = subtotal >= 1_000_000 ? 0 : 30_000;
            var order = new Order
            {
                OrderCode = code, UserId = customer.Id, Status = status, ShippingMethod = ShippingMethod.Standard,
                Subtotal = subtotal, ShippingFee = shipping, TotalAmount = subtotal + shipping,
                RecipientName = address.RecipientName, PhoneNumber = address.PhoneNumber, AddressLine = address.AddressLine,
                Ward = address.Ward, District = address.District, City = address.City,
                CreatedAt = created, UpdatedAt = created, Items = items,
                StatusHistory = [new OrderStatusHistory { ToStatus = OrderStatus.Pending, ChangedByUserId = customer.Id, ChangedAt = created, Note = "Order placed" }],
                Payment = new Payment
                {
                    Method = method, Status = paymentStatus, Amount = subtotal + shipping, CreatedAt = created, UpdatedAt = created,
                    ConfirmedByUserId = paymentStatus == PaymentStatus.Paid ? staff.Id : null,
                    ConfirmedAt = paymentStatus == PaymentStatus.Paid ? created.AddDays(2) : null,
                },
            };
            if (status != OrderStatus.Pending)
            {
                order.StatusHistory.Add(new OrderStatusHistory { FromStatus = OrderStatus.Pending, ToStatus = status, ChangedByUserId = staff.Id, ChangedAt = created.AddDays(1) });
            }
            db.Orders.Add(order);
            return order;
        }

        AddOrder("SMDEMO0001", OrderStatus.Completed, PaymentMethod.COD, PaymentStatus.Paid, 20, (pegasus, 2, 1), (tee, 1, 2));
        AddOrder("SMDEMO0002", OrderStatus.Completed, PaymentMethod.BankTransfer, PaymentStatus.Paid, 9, (novablast, 0, 1));
        AddOrder("SMDEMO0003", OrderStatus.Shipping, PaymentMethod.COD, PaymentStatus.Pending, 3, (tee, 4, 1));
        AddOrder("SMDEMO0004", OrderStatus.Pending, PaymentMethod.BankTransfer, PaymentStatus.Pending, 1, (pegasus, 6, 1));

        db.Reviews.Add(new Review
        {
            ProductId = pegasus.Id, UserId = customer.Id, Rating = 5, Comment = "Very comfortable, great for long runs!",
            Status = ReviewStatus.Approved, CreatedAt = now.AddDays(-15), UpdatedAt = now.AddDays(-15),
        });
        db.WishlistItems.Add(new WishlistItem { UserId = customer.Id, ProductId = novablast.Id, CreatedAt = now });

        await db.SaveChangesAsync();
        logger.LogInformation("Demo data seeded: {Products} products, 3 accounts.", products.Count);
    }

    private User NewUser(string name, string email, UserRole role, string password, DateTime createdAt)
    {
        var user = new User
        {
            FullName = name, Email = email, NormalizedEmail = TextNormalizer.Key(email), Role = role,
            CreatedAt = createdAt, UpdatedAt = createdAt,
        };
        user.PasswordHash = hasher.Hash(user, password);
        return user;
    }
}
