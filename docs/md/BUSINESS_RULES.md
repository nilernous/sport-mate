# Sport Mate --- Business Rules

## 1. Purpose and Scope

This document defines the business rules for Sport Mate, a sports
e-commerce application using Flutter, ASP.NET Core Web API, and SQL
Server. The API is the source of truth for access control, pricing,
inventory, orders, and payment state. Flutter-side validation is for
usability and never replaces server validation.

## 2. Roles and Access Control

### BR-001 --- Supported roles

The system supports three authenticated roles: `Customer`, `Staff`, and
`Admin`. `Guest` is an unauthenticated actor, not a persisted role.

### BR-002 --- Public access

Guests may browse active products, view product details, and
search/filter/sort the public catalog. Protected operations require
authentication.

### BR-003 --- Customer ownership

A Customer may access or modify only their own profile, addresses, cart,
orders, wishlist, and reviews, subject to the rules below.

### BR-004 --- Staff permissions

Staff may perform assigned operational functions, including catalog
maintenance, inventory adjustments, order processing, manual payment
confirmation, and review moderation. Staff may not manage roles or grant
themselves additional permissions.

### BR-005 --- Admin permissions

Admin may manage users and roles, coupons, catalog, inventory, orders,
reviews, and reports. The API enforces all role checks.

### BR-006 --- Identity source

The API derives the current user's identity and role from validated
authentication claims. It must not trust a client-supplied user ID or
role for authorization decisions.

### BR-007 --- Account status

Disabled accounts may not sign in or use protected endpoints. Disabling
an account preserves historical orders and related records.

## 3. Authentication and User Data

### BR-008 --- Unique email

User email must be unique under the application's normalization and
case-comparison policy.

### BR-009 --- Password storage

Passwords must be stored as secure password hashes, never plaintext or
reversibly encrypted values.

### BR-010 --- Password reset

Password reset tokens must be time-limited, single-use, and validated by
the backend. Responses should not reveal whether an email is registered.

### BR-011 --- Profile update

Users may update only allowed profile fields. A Customer cannot change
their role, account status, or administrative permissions.

### BR-012 --- Address ownership

Only the address owner or an explicitly authorized administrator may
access or modify an address. Checkout verifies address ownership.

### BR-013 --- Order address snapshot

An order preserves the delivery address used at purchase. Later edits to
the user's address book must not silently alter historical orders.

## 4. Product Catalog

### BR-014 --- Product status

Only active and publicly available products appear in the public
catalog. Inactive products cannot be newly purchased.

### BR-015 --- Category and brand references

A product may reference only existing, valid categories and brands.
Deleting a referenced category or brand must be blocked or handled
through a documented deactivation strategy.

### BR-016 --- Product variants

Products requiring size/color choices use product variants. Each variant
belongs to one product and represents a purchasable combination.

### BR-017 --- Unique SKU

Each SKU must be unique according to the application's normalization
policy.

### BR-018 --- Price validity

Product and variant selling prices must be valid non-negative decimal
values. Additional discount constraints are validated by the API.

### BR-019 --- Product images

An image must belong to a valid product. Validate allowed image types
and reasonable file size when upload is supported.

### BR-020 --- Referenced product deletion

Products, variants, and categories referenced by historical orders
should normally be deactivated or archived instead of physically
deleted.

### BR-021 --- Public catalog filters

Search, sorting, and filtering return only publicly available products.
Sort fields must be allow-listed.

## 5. Inventory

### BR-022 --- Variant-level stock

Inventory is tracked per purchasable product variant, not only at the
parent product level.

### BR-023 --- Non-negative stock

Available stock must never become negative.

### BR-024 --- Server-side stock validation

The API validates current stock when an order is created. Client-side
stock/cart values are not authoritative.

### BR-025 --- Atomic inventory changes

Stock changes associated with order placement or cancellation must be
applied consistently. Use transactions and safe concurrency handling to
prevent overselling.

### BR-026 --- Inventory adjustment permission

Only Staff and Admin may make manual inventory adjustments.

### BR-027 --- Inventory movement history

Inventory adjustments should record variant, quantity change, time,
actor, and reason.

### BR-028 --- Cancellation stock policy

When an order is cancelled, stock must be restored or a reservation
released exactly once according to the selected inventory strategy.

## 6. Cart and Checkout

### BR-029 --- Cart ownership

Each Customer's cart is isolated from other users. A Customer cannot
read or modify another Customer's cart.

### BR-030 --- Valid cart item

A cart item must reference an active, purchasable variant and a positive
integer quantity.

### BR-031 --- Cart is not a price guarantee

Cart prices are indicative. The backend re-reads current prices,
discounts, availability, and fees during checkout.

### BR-032 --- Checkout address

The selected delivery address must belong to the current Customer and be
valid for the selected shipping option.

### BR-033 --- Server-calculated totals

The API calculates subtotal, discount, shipping fee, and final total.
Client-submitted totals are ignored or rejected.

### BR-034 --- Monetary precision

Store money using SQL Server `decimal` with documented precision and
scale. Avoid binary floating-point arithmetic for monetary calculations.

### BR-035 --- Checkout consistency

Order creation validates cart, address, coupon, stock, and payment
method together. If a critical step fails, the operation must not leave
a partial order or inconsistent inventory.

### BR-036 --- Duplicate submission

Prevent duplicate orders caused by repeated submission or retry. Use an
idempotency key or another documented strategy where feasible.

### BR-037 --- Cart cleanup

After successful order placement, purchased cart items should be removed
or reconciled so they are not unintentionally purchased again.

## 7. Orders

### BR-038 --- Order ownership

Customers may view and cancel only their own orders. Staff and Admin may
view cross-customer orders according to permissions.

### BR-039 --- Order item snapshot

Each order item preserves product name/SKU, variant details, quantity,
and unit price at purchase time. Later catalog edits must not rewrite
historical purchase details.

### BR-040 --- Order states

Use a defined order lifecycle, for example:
`Pending → Confirmed → Shipping → Completed`. `Pending` or `Confirmed`
may transition to `Cancelled` according to policy. Other transitions
must be explicitly defined.

### BR-041 --- Valid state transitions

Only allowed order-state transitions may be applied. Invalid transitions
return a conflict response.

### BR-042 --- Customer cancellation

A Customer may cancel only an order they own and only while it is in a
cancellable state. Recommended initial policy: cancellation before
shipping; the team must confirm the exact cutoff.

### BR-043 --- Staff order processing

Staff and Admin may update order states only through allowed transitions
and must not bypass payment or inventory rules.

### BR-044 --- Historical integrity

Completed or cancelled orders remain available for history and
reporting. Do not hard-delete orders with associated payment or
inventory records.

### BR-045 --- Order totals are immutable snapshots

Once placed, confirmed prices and totals do not change because product
prices or coupon definitions change. Corrections follow an explicit
adjustment/refund process.

## 8. Payment

### BR-046 --- Separate payment and order states

Payment status and order status are separate concepts and must be stored
separately.

### BR-047 --- Initial payment methods

The initial project supports Cash on Delivery (COD) and bank transfer
with manual confirmation. A payment gateway is out of scope unless
separately approved.

### BR-048 --- Customer cannot self-confirm payment

A Customer cannot mark their own payment as paid. Manual bank transfer
confirmation requires Staff or Admin authorization and verification.

### BR-049 --- COD status

For COD, payment remains pending until collection is confirmed according
to the agreed workflow.

### BR-050 --- Manual bank transfer

Staff/Admin must verify transfer amount and reference before
confirmation. Record who confirmed it and when.

### BR-051 --- Duplicate payment confirmation

Payment confirmation must be idempotent or reject repeated confirmation
without duplicating side effects.

### BR-052 --- Payment amount

The payment amount must match the amount due for the associated order,
subject to a documented adjustment/refund flow.

### BR-053 --- Refund policy

Cancelling an already-paid order does not automatically mean a refund is
complete. If refunds are in scope, record their state and handling.

## 9. Promotions and Coupons

### BR-054 --- Unique coupon code

Coupon codes must be unique under the chosen normalization policy.

### BR-055 --- Coupon validity window

A coupon may be applied only when enabled and within its configured
start/end time window.

### BR-056 --- Coupon eligibility

The backend checks minimum order value, eligible products/categories,
per-user limits, overall usage limits, and configured restrictions.

### BR-057 --- Discount bounds

A discount cannot produce a negative order total. Percentage discounts
must obey a configured maximum discount if present.

### BR-058 --- Coupon revalidation

A coupon is revalidated at order creation even if accepted by a checkout
preview.

### BR-059 --- Coupon usage consistency

Coupon usage is recorded when the order commits according to the
selected policy. Failed order creation must not consume usage.

### BR-060 --- Coupon updates

Coupon changes must not rewrite totals on existing orders.

## 10. Reviews and Wishlist

### BR-061 --- Review eligibility

Only authenticated Customers may create reviews. Recommended policy:
require a qualifying purchase; define whether the order must be
completed first.

### BR-062 --- Review ownership

A Customer may edit or delete only their own review, subject to
moderation and project policy.

### BR-063 --- Review uniqueness

If only one review per customer per product or order item is allowed,
enforce it with backend validation and a database constraint where
practical.

### BR-064 --- Review rating

Ratings must be within the configured range, recommended 1 through 5.
Validate text length and allowed content.

### BR-065 --- Review moderation

Only Staff and Admin may moderate reviews. Hidden/rejected reviews must
not appear in public review listings.

### BR-066 --- Wishlist ownership

A wishlist belongs to the current Customer. Prevent duplicate entries
for the same product.

## 11. Reporting

### BR-067 --- Admin-only reports

Sales dashboard, order reports, and best-selling product reports are
accessible only to Admin unless Staff access is explicitly granted.

### BR-068 --- Revenue definition

Document the revenue metric. Recommended default: count successfully
paid orders; count COD only after collection confirmation; exclude
cancelled and unpaid orders.

### BR-069 --- Date range validation

Report date ranges must be valid and follow a consistent timezone
policy. Reject invalid ranges.

### BR-070 --- Best-selling calculation

Define best-selling products using a consistent measure, such as
quantity sold in qualifying non-cancelled orders or completed/paid
orders.

## 12. API and Data Integrity

### BR-071 --- Server-side validation

All security- and business-relevant fields are validated by the API,
even if Flutter validates them first.

### BR-072 --- Consistent errors

Return documented HTTP status codes and a consistent error response. Do
not return stack traces, SQL details, credentials, or signing keys.

### BR-073 --- Database constraints

Use primary keys, foreign keys, unique constraints, check constraints,
and indexes where they protect data integrity.

### BR-074 --- Transaction boundaries

Use transactions for operations that must succeed or fail as a unit,
especially order creation, stock updates, and coupon usage.

### BR-075 --- Concurrency

Use conditional updates, row versioning, or suitable transaction
isolation for inventory and state changes. On conflict, return a clear
error and do not oversell.

### BR-076 --- Audit-sensitive actions

Record actor and timestamp for important administrative changes,
inventory adjustments, order-state changes, and manual payment
confirmations where practical.

### BR-077 --- Secret handling

Database credentials and JWT signing keys must not be committed to
source control or returned to clients.

### BR-078 --- Authentication enforcement

Protected endpoints require a valid token and role checks are enforced
server-side. Hiding Flutter screens is not sufficient.

## 13. Decisions to Confirm Before Implementation

1.  Does stock get reserved at order creation or deducted immediately?
2.  What is the cancellation cutoff and inventory restoration behavior?
3.  Is bank transfer always manual, or will a real payment gateway be
    integrated?
4.  Do reviews require a completed purchase? Is one review allowed per
    product or per order?
5.  Can coupons be combined? Are limits per customer, order, or global?
6.  Can Staff edit product prices or access customer contact details?
7.  What exact definitions will be used for revenue and best-selling
    products?
8.  Will account removal mean deactivation, anonymization, or physical
    deletion?

## 14. Minimum Acceptance Criteria

-   Customers cannot access another user's private resources.
-   Staff cannot grant roles or access Admin-only operations unless
    explicitly authorized.
-   SKU remains unique.
-   Stock cannot become negative due to concurrent checkout.
-   Order totals are calculated server-side and saved as a historical
    snapshot.
-   Coupon eligibility is rechecked at order creation.
-   Customers cannot self-confirm payment.
-   Invalid order-state transitions are rejected.
-   Inactive products cannot be purchased.
-   Reports follow the documented revenue definition.
