# Sport Mate — Backend (ASP.NET Core Web API)

.NET 8 · EF Core 8 · SQL Server · JWT. Requests flow **Controller → Service → EF Core → SQL Server**
(see `docs/md/BACKEND_ARCHITECTURE.md`), split into four projects:

```text
SportMate.Domain          Entities and enums. No dependencies.
SportMate.Application     DTOs, use-case services (business rules), interfaces, settings.  → Domain
SportMate.Infrastructure  EF Core DbContext, configurations, migrations, seeder,
                          JWT issuing, password hashing, file storage.                     → Application, Domain
SportMate.API             Controllers, middleware, auth setup, Program.cs, appsettings.    → Application, Infrastructure
```

- Services depend on interfaces declared in Application: `IApplicationDbContext`, `ITokenService`,
  `IPasswordHasher` and `IFileStorage`. Infrastructure implements them, and each layer registers its
  own services (`AddApplication`, `AddInfrastructure`).
- Application uses EF Core's provider-neutral LINQ and transaction APIs only. SQL Server is referenced
  only by Infrastructure.
- Business rules belong in `SportMate.Application/Services`. Controllers stay thin.

## Run locally

Prerequisites: .NET SDK 8 (pinned by `global.json`), SQL Server (Express is fine).

```bash
cd backend
dotnet tool restore                                   # installs dotnet-ef 8.0.31 (local tool)
cd SportMate.API
dotnet run --launch-profile http                      # http://localhost:5005/swagger
```

- A development JWT key is already set in `appsettings.Development.json` (`Jwt:Key`), so the team can
  run without extra setup. It is used only in Development. For any real deployment, set a different key
  through an environment variable (`Jwt__Key`) or a secret store, and never reuse the dev key (BR-077).
- The connection string in `appsettings.Development.json` targets `.\SQLEXPRESS` with Windows
  authentication and database `SportMateDb`. Change it there (or with user-secrets) for your machine.
- In Development the API applies migrations and seeds demo data on startup when the database is empty.
- Schema changes: from `backend/`, run
  `dotnet ef migrations add <Name> --project SportMate.Infrastructure --startup-project SportMate.API -o Persistence/Migrations`,
  review the migration, then restart the API.

### Demo accounts (Development seed only)

| Role     | Email                   | Password       |
|----------|-------------------------|----------------|
| Admin    | `admin@sportmate.vn`    | `Admin@123`    |
| Staff    | `staff@sportmate.vn`    | `Staff@123`    |
| Customer | `customer@sportmate.vn` | `Customer@123` |

Demo coupons: `WELCOME10`, `SALE50K`, `RUN15` (running shoes only), `EXPIRED20` (expired).

### Smoke test

With the API running on a freshly seeded database:

```bash
pip install requests
python scripts/smoke_test.py
```

It exercises the Iteration 1 and 2 endpoints, the role boundaries and a concurrent checkout. To reseed, drop
`SportMateDb` and restart the API.

## API conventions

- Base path `/api/v1`; JSON with camelCase properties and enums as strings; money in VND (`decimal(18,2)`).
- Lists return `{ items, page, pageSize, totalItems, totalPages }` (`page`, `pageSize` ≤ 100).
- Errors are RFC 7807 Problem Details (`type`, `title`, `status`, `detail`, optional `errors`).
- `/admin/*` is shared by **Staff and Admin**. Coupons are **Admin only** (Staff get 403). The mobile
  app hides features by role, but the API enforces every check.
- Customer-only endpoints: addresses, cart, checkout, orders, payments, wishlist.
- This branch serves **Iterations 1 and 2**. The data model (entities, migration, seed data) already
  covers all iterations, so Iteration 3 adds endpoints without a new migration.

### Endpoints added beyond `API_DESIGN.md`

| Endpoint | Purpose |
|---|---|
| `GET /brands`, `GET /brands/{id}` | Public brand list for the filter UI |
| `GET /products/filters` | Categories, brands, sizes, colors and price range for filters |
| `GET /admin/categories`, `GET /admin/categories/{id}` | Includes inactive categories |
| `GET/POST/PUT/DELETE /admin/brands[/{id}]` | Brand management (UC-022 – UC-025) |
| `GET /admin/products`, `GET /admin/products/{id}` | Includes inactive products |
| `GET/POST /admin/products/{id}/variants`, `GET/PUT/DELETE /admin/variants/{id}` | Variants |
| `GET /admin/inventory/movements` | Stock movement history |
| `GET /admin/orders/{id}`, `GET /admin/payments/{id}` | Detail views for staff |
| `GET /admin/coupons/{id}` | Coupon detail |

`POST /orders` accepts an optional `Idempotency-Key` header: retrying with the same key returns the
original order (200) instead of creating a duplicate.

## Decisions for BUSINESS_RULES §13

These decisions cover the whole project; some (reviews, reports, user management) apply from Iteration 3.

| # | Decision |
|---|---|
| 1 | Stock is **deducted at order creation** with a conditional update, so concurrent checkouts can't oversell. |
| 2 | Customers can cancel while the order is **Pending or Confirmed**. Cancelling restores stock exactly once and gives back the coupon use. |
| 3 | Bank transfer is **confirmed manually** by Staff/Admin, who enter the received amount and reference. The amount must match the amount due. Confirmation moves a Pending order to Confirmed. A bank-transfer order cannot ship until it's paid. |
| 4 | A review requires a **Completed** order containing the product. **One review per customer per product.** Reviews are visible immediately; Staff/Admin can hide or reject them. |
| 5 | **One coupon per order.** A coupon can have a global usage limit, a per-customer limit, a minimum order value, an optional category restriction and a maximum discount (for percentages). |
| 6 | Staff **can** edit prices and see the customer contact details shown on orders. They cannot manage users, roles or coupons, or see reports. |
| 7 | **Revenue** = paid payments of non-cancelled orders placed in the range. COD counts once collected; Staff completing a COD order counts as collection. **Best-selling** = quantity sold in those same orders. Report dates use UTC+7. |
| 8 | Removing an account means **disabling** it. Its orders and reviews are kept. The last active Admin cannot be disabled or demoted. |

Other policies:

- **Sign Out and Token Security:** Signing out invalidates all active tokens associated with the user's account. Tokens are also invalidated when the user changes their password, the account is disabled, or the user's role is updated. A token version is verified on each request to ensure security.

- **Password Reset:** Since email integration is not included in the current project scope, password reset tokens are recorded in the API logs instead of being delivered via email.

- **Shipping Fees:** Standard shipping costs 30,000 VND and becomes free when the order total reaches 1,000,000 VND after discounts. Express shipping has a fixed fee of 50,000 VND. These settings can be adjusted in the `Shipping` section of `appsettings.json`.

- **Safe Deletion:** When a category, brand, product, variant, or coupon is still referenced by other records, the system deactivates it rather than permanently deleting it. The API response specifies the action performed through the `action` field, returning either `Deleted` or `Deactivated`.