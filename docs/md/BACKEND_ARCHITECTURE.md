# Sport Mate --- Backend Architecture

## 1. Overview

Sport Mate's backend is a single **ASP.NET Core Web API** application
using **C#**, **Entity Framework Core**, and **SQL Server**.

Use a simple layered structure:

**Controller → Service → Entity Framework Core → SQL Server**

This is sufficient for a team project with a full e-commerce feature
set. Do not introduce microservices, CQRS, MediatR, distributed
messaging, or mandatory repository abstractions without a concrete
requirement.

## 2. Technology Stack

-   **Runtime/framework:** ASP.NET Core Web API
-   **Language:** C#
-   **ORM:** Entity Framework Core
-   **Database:** Microsoft SQL Server
-   **Authentication:** JWT Bearer Authentication
-   **Authorization:** Role-based authorization and ownership checks
-   **API documentation:** Swagger / OpenAPI
-   **Schema changes:** EF Core Migrations

Use a supported .NET version agreed on by the team and keep the SDK
version consistent across development environments.

## 3. Project Structure

``` text
SportMate.API/
├── Controllers/
├── DTOs/
│   ├── Requests/
│   └── Responses/
├── Models/
├── Data/
│   ├── ApplicationDbContext.cs
│   └── Configurations/
├── Services/
├── Interfaces/
├── Middleware/
├── Mappings/
├── Migrations/
├── Program.cs
├── appsettings.json
└── appsettings.Development.json
```

### Responsibilities

-   `Controllers/`: HTTP routing, request binding, authorization
    attributes, and HTTP responses.
-   `DTOs/`: explicit request and response contracts; do not expose EF
    entities directly as API contracts.
-   `Models/`: database entities and domain enums.
-   `Data/`: EF Core `DbContext`, entity configuration, and migrations.
-   `Services/`: business rules and use-case logic.
-   `Interfaces/`: service interfaces where they help testing or
    separation; avoid interfaces for every trivial class by default.
-   `Middleware/`: shared exception handling or other cross-cutting HTTP
    behavior.
-   `Mappings/`: mapping logic if it becomes repetitive; manual mapping
    is fine for a small project.
-   `Migrations/`: database schema history managed by EF Core.

## 4. Feature Modules

Organize controllers, DTOs, and services around these feature areas:

1.  **Auth & Users** --- registration, login, profile, addresses, roles.
2.  **Catalog** --- categories, brands, products, variants, and images.
3.  **Cart** --- cart retrieval and item changes.
4.  **Orders & Checkout** --- order creation, order history,
    cancellation, and status transitions.
5.  **Payments** --- payment records and manual payment confirmation or
    COD.
6.  **Inventory** --- stock quantities and stock adjustments.
7.  **Promotions** --- coupons, eligibility, expiry, and usage limits.
8.  **Reviews** --- review creation and moderation.
9.  **Admin & Reports** --- administrative operations and basic sales
    summaries.

Keep this as one deployable API. Feature areas are logical groupings,
not independent services.

## 5. Request Flow

1.  ASP.NET Core routes the request to a controller.
2.  Authentication middleware validates the bearer token when required.
3.  Authorization checks role and resource ownership.
4.  The controller validates/binds the request and calls a service.
5.  The service enforces business rules and uses `ApplicationDbContext`.
6.  EF Core queries or updates SQL Server.
7.  The controller returns a suitable HTTP status code and DTO.

Controllers should remain thin. Do not place complex pricing, stock,
coupon, or order-state logic directly inside controllers.

## 6. Database Entities

Suggested core entities:

-   `User`, `Role`, `UserAddress`
-   `Category`, `Brand`, `Product`, `ProductVariant`, `ProductImage`
-   `Cart`, `CartItem`
-   `Order`, `OrderItem`
-   `Payment`
-   `Coupon`, `CouponUsage`
-   `Review`

Optional entities such as `StockMovement`, `Shipment`, or `WishlistItem`
can be added if required by the selected features.

### Important data rules

-   A product can have multiple variants, such as size and color. Track
    SKU and stock at the variant level.
-   Store monetary values using SQL Server `decimal`, with an explicitly
    selected precision and scale.
-   `OrderItem` should snapshot product name/SKU and unit price at
    purchase time.
-   Store the order's delivery address as a snapshot or otherwise
    preserve the address used for that order.
-   Add foreign keys, indexes, and unique constraints for fields such as
    SKU and user email where appropriate.
-   Use transactions for order creation and stock changes that must
    succeed or fail together.
-   Prevent overselling by validating and updating stock safely under
    concurrent requests.
-   Store payment status separately from order status.

## 7. Authentication and Authorization

Use JWT Bearer Authentication for protected API endpoints.

Suggested roles:

-   `Customer`
-   `Admin`

Examples:

``` csharp
[Authorize]
[HttpGet("my-orders")]
public async Task<IActionResult> GetMyOrders()
{
    // Resolve the user ID from validated claims.
    // Return only orders belonging to that user.
    return Ok();
}

[Authorize(Roles = "Admin")]
[HttpPost("products")]
public async Task<IActionResult> CreateProduct(
    CreateProductRequest request)
{
    // Validate and create the product through a service.
    return Ok();
}
```

The snippets illustrate authorization placement only; actual
implementations must return real data and enforce ownership and business
rules.

Security rules:

-   Hash passwords with a proven password-hashing implementation; never
    store plaintext passwords.
-   Validate JWT signature, issuer, audience, and expiry according to
    the configured token setup.
-   Obtain the current user ID from validated claims, not from a
    client-supplied user ID.
-   Require `Admin` authorization for administrative operations.
-   Enforce resource ownership for customer addresses, carts, orders,
    and reviews.
-   Validate all input on the server and avoid returning stack traces or
    secrets in error responses.
-   Keep signing keys and database credentials out of source control.

## 8. Business Rules

### Products and inventory

-   Only active products should appear in the customer catalog.
-   A variant must belong to a valid product.
-   The backend validates stock and price at checkout.
-   Stock changes must be consistent with order placement and
    cancellation.

### Orders

-   The server calculates subtotal, discount, shipping fee, and final
    total.
-   A client must never be trusted to submit the authoritative order
    total.
-   Capture product details and prices in order items when the order is
    created.
-   Define allowed order-state transitions, for example: `Pending`,
    `Confirmed`, `Shipping`, `Completed`, `Cancelled`.
-   Release or restore stock on cancellation according to the defined
    order lifecycle.

### Payments

-   Keep payment status separate, for example: `Pending`, `Paid`,
    `Failed`, `Refunded`.
-   For COD, payment can remain pending until collection is confirmed.
-   For bank transfer handled manually, an authorized admin confirms
    payment after checking the transfer.
-   Do not mark an order as paid solely because the client reports
    success.

### Coupons and reviews

-   Validate coupon expiry, usage limits, minimum order value, and
    eligibility on the server.
-   Prevent duplicate coupon usage where the rules prohibit it.
-   Allow reviews only according to the project's chosen
    purchase-verification rule.

## 9. Error Handling and Validation

Use DTO validation for incoming requests and return consistent HTTP
responses.

Recommended status codes:

-   `200 OK` --- successful read/update/action
-   `201 Created` --- resource created
-   `204 No Content` --- successful action without a response body
-   `400 Bad Request` --- invalid request
-   `401 Unauthorized` --- missing or invalid authentication
-   `403 Forbidden` --- authenticated but not authorized
-   `404 Not Found` --- resource does not exist or is not accessible
-   `409 Conflict` --- conflicting state, duplicate resource, or stock
    conflict
-   `500 Internal Server Error` --- unexpected server error

Use centralized exception handling to prevent raw stack traces from
reaching clients.

## 10. Configuration

Keep environment-specific settings in configuration files and
environment variables. `appsettings.json` may contain non-secret
defaults. Do not commit production credentials or JWT signing keys.

Use EF Core migrations to create and update the schema. Review
migrations before applying them to a shared database.

## 11. Testing Scope

Keep testing proportional to the project. Prioritize manual or automated
checks for:

-   Login and role authorization
-   Customer ownership of orders and addresses
-   Product and variant CRUD
-   Checkout totals and coupon rules
-   Concurrent stock changes
-   Order cancellation and payment-state transitions

## 12. Scope Exclusions

No microservices, Redis, message broker, CQRS, distributed tracing,
elaborate repository/unit-of-work framework, deployment pipeline, or
production operations platform is required for the current project
scope.

## 13. Key Design Rule

**Controllers handle HTTP; services enforce business rules; EF Core
persists data; SQL Server stores the source of truth.**
