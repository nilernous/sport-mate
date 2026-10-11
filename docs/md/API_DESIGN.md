# Sport Mate --- API Design

## 1. Overview

Sport Mate exposes a REST API from ASP.NET Core Web API for the Flutter
application. Requests and responses use JSON.

-   **Base path:** `/api/v1`
-   **Authentication:** JWT Bearer token for protected endpoints
-   **Database:** SQL Server accessed through Entity Framework Core
-   **API documentation:** Swagger / OpenAPI

The endpoint list below is the proposed contract. Implement only
endpoints required by the agreed feature scope, but keep naming and
response conventions consistent.

## 2. Conventions

### HTTP methods

-   `GET` --- retrieve data
-   `POST` --- create a resource or execute an action
-   `PUT` --- replace/update a resource
-   `PATCH` --- partially update a resource or state
-   `DELETE` --- remove a resource when deletion is allowed

### Naming and parameters

-   Use plural resource names: `/products`, `/orders`, `/categories`.
-   Use route IDs for individual resources: `/products/{productId}`.
-   Use query parameters for filtering, sorting, and pagination.
-   Use ISO 8601 timestamps for date/time values.
-   Use decimal JSON numbers for monetary amounts; document the currency
    as VND.
-   Never accept a client-provided role, owner ID, authoritative price,
    or final order total as trusted input.

### Pagination

Example:

`GET /api/v1/products?page=1&pageSize=20&sortBy=price&sortOrder=asc`

Suggested response shape:

``` json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "totalItems": 0,
  "totalPages": 0
}
```

Apply a reasonable maximum page size.

## 3. Authentication

  -------------------------------------------------------------------------------
  Method            Endpoint                  Access            Purpose
  ----------------- ------------------------- ----------------- -----------------
  POST              `/auth/register`          Public            Register customer

  POST              `/auth/login`             Public            Authenticate and
                                                                issue token

  POST              `/auth/refresh`           If refresh tokens Issue a renewed
                                              are implemented   access token

  POST              `/auth/logout`            Authenticated     Logout/revoke
                                                                refresh token if
                                                                supported

  POST              `/auth/forgot-password`   Public            Start password
                                                                reset

  POST              `/auth/reset-password`    Public with reset Reset password
                                              token             

  GET               `/users/me`               Authenticated     Get current
                                                                profile

  PUT               `/users/me`               Authenticated     Update current
                                                                profile

  PUT               `/users/me/password`      Authenticated     Change password
  -------------------------------------------------------------------------------

Do not implement a refresh endpoint unless the backend has a defined,
secure refresh-token flow.

### Example login request

``` json
{
  "email": "customer@example.com",
  "password": "example-password"
}
```

### Example login response

``` json
{
  "accessToken": "<jwt>",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 12,
    "fullName": "Example Customer",
    "email": "customer@example.com",
    "role": "Customer"
  }
}
```

The response is illustrative. Use the actual configured token lifetime
and avoid exposing sensitive user fields.

## 4. Categories and Products

  -----------------------------------------------------------------------------------------
  Method            Endpoint                        Access            Purpose
  ----------------- ------------------------------- ----------------- ---------------------
  GET               `/categories`                   Public            List categories

  GET               `/categories/{id}`              Public            Get category

  GET               `/products`                     Public            List, filter, sort,
                                                                      and paginate products

  GET               `/products/{id}`                Public            Product detail and
                                                                      variants

  GET               `/products/{id}/reviews`        Public            List product reviews

  POST              `/admin/categories`             Admin             Create category

  PUT               `/admin/categories/{id}`        Admin             Update category

  DELETE            `/admin/categories/{id}`        Admin             Delete if allowed

  POST              `/admin/products`               Admin             Create product

  PUT               `/admin/products/{id}`          Admin             Update product

  PATCH             `/admin/products/{id}/status`   Admin             Activate/deactivate
                                                                      product

  DELETE            `/admin/products/{id}`          Admin             Delete/archive if
                                                                      allowed
  -----------------------------------------------------------------------------------------

Suggested product-list filters:

-   `categoryId`
-   `brandId`
-   `keyword`
-   `minPrice`
-   `maxPrice`
-   `size`
-   `color`
-   `sortBy`
-   `sortOrder`
-   `page`
-   `pageSize`

Use stable identifiers for products and variants. Product SKU and
inventory quantity should be managed by the backend.

## 5. Addresses

  ----------------------------------------------------------------------------------
  Method            Endpoint                     Access            Purpose
  ----------------- ---------------------------- ----------------- -----------------
  GET               `/users/me/addresses`        Authenticated     List own
                                                                   addresses

  POST              `/users/me/addresses`        Authenticated     Create address

  PUT               `/users/me/addresses/{id}`   Authenticated     Update own
                                                                   address

  DELETE            `/users/me/addresses/{id}`   Authenticated     Delete own
                                                                   address
  ----------------------------------------------------------------------------------

The API must ensure the address belongs to the current user. Checkout
must not allow a customer to use another user's address by guessing its
ID.

## 6. Cart

  ------------------------------------------------------------------------------
  Method            Endpoint                 Access            Purpose
  ----------------- ------------------------ ----------------- -----------------
  GET               `/cart`                  Authenticated     Get current
                                                               user's cart

  POST              `/cart/items`            Authenticated     Add product
                                                               variant and
                                                               quantity

  PATCH             `/cart/items/{itemId}`   Authenticated     Change quantity

  DELETE            `/cart/items/{itemId}`   Authenticated     Remove an item

  DELETE            `/cart`                  Authenticated     Clear cart
  ------------------------------------------------------------------------------

Example add-to-cart request:

``` json
{
  "productVariantId": 42,
  "quantity": 2
}
```

The server validates that the variant is active and available. Cart
prices are indicative; the server recalculates totals during checkout.

## 7. Checkout and Orders

  -----------------------------------------------------------------------------------
  Method            Endpoint                      Access            Purpose
  ----------------- ----------------------------- ----------------- -----------------
  POST              `/checkout/preview`           Authenticated     Validate cart and
                                                                    calculate a
                                                                    preview

  POST              `/orders`                     Authenticated     Create order from
                                                                    validated
                                                                    checkout input

  GET               `/orders`                     Authenticated     List current
                                                                    user's orders

  GET               `/orders/{id}`                Authenticated     Get own order
                                                                    detail

  POST              `/orders/{id}/cancel`         Authenticated     Request
                                                                    cancellation when
                                                                    allowed

  GET               `/admin/orders`               Admin             List/filter all
                                                                    orders

  PATCH             `/admin/orders/{id}/status`   Admin             Update order
                                                                    status
  -----------------------------------------------------------------------------------

Example order request:

``` json
{
  "addressId": 8,
  "shippingMethod": "Standard",
  "paymentMethod": "COD",
  "couponCode": "SPORT10"
}
```

The backend must load product prices and stock, validate the address and
coupon, calculate all totals, and create the order transactionally. Do
not accept `userId`, `unitPrice`, `subtotal`, `discountAmount`, or
`totalAmount` as authoritative fields from the client.

For safe retries, consider accepting an idempotency key for order
creation. At minimum, protect against accidental duplicate submissions
in the application flow.

## 8. Payments

  ---------------------------------------------------------------------------------------------
  Method            Endpoint                                Access            Purpose
  ----------------- --------------------------------------- ----------------- -----------------
  GET               `/orders/{orderId}/payment`             Authenticated,    Get payment
                                                            owner             status for own
                                                                              order

  POST              `/orders/{orderId}/payment`             Authenticated,    Initiate
                                                            owner             supported payment
                                                                              method if
                                                                              required

  PATCH             `/admin/payments/{paymentId}/confirm`   Admin             Confirm manually
                                                                              verified bank
                                                                              transfer

  PATCH             `/admin/payments/{paymentId}/status`    Admin             Update permitted
                                                                              payment state
  ---------------------------------------------------------------------------------------------

Keep payment and order states separate. Do not expose a public endpoint
that lets a customer mark a payment as paid. If no payment gateway is
integrated, COD and manually confirmed bank transfer are sufficient.

## 9. Coupons and Promotions

  -----------------------------------------------------------------------------
  Method            Endpoint                Access            Purpose
  ----------------- ----------------------- ----------------- -----------------
  POST              `/coupons/validate`     Public or         Validate a code
                                            authenticated     against a cart
                                            according to      preview
                                            policy            

  GET               `/admin/coupons`        Admin             List coupons

  POST              `/admin/coupons`        Admin             Create coupon

  PUT               `/admin/coupons/{id}`   Admin             Update coupon

  DELETE            `/admin/coupons/{id}`   Admin             Disable/delete if
                                                              allowed
  -----------------------------------------------------------------------------

Coupon validation during checkout must be repeated on the server. A
prior validation response does not guarantee that a coupon remains valid
when the order is created.

## 10. Reviews and Wishlist

  ----------------------------------------------------------------------------------------------
  Method            Endpoint                                 Access            Purpose
  ----------------- ---------------------------------------- ----------------- -----------------
  POST              `/products/{productId}/reviews`          Authenticated     Create eligible
                                                                               review

  PUT               `/reviews/{id}`                          Review owner or   Update review
                                                             Admin             according to
                                                                               policy

  DELETE            `/reviews/{id}`                          Review owner or   Delete if allowed
                                                             Admin             

  PATCH             `/admin/reviews/{id}/status`             Admin             Moderate review

  GET               `/users/me/wishlist`                     Authenticated     List wishlist

  POST              `/users/me/wishlist/items`               Authenticated     Add product

  DELETE            `/users/me/wishlist/items/{productId}`   Authenticated     Remove product
  ----------------------------------------------------------------------------------------------

Wishlist endpoints are optional if wishlist is outside the agreed scope.

## 11. Inventory and Admin

  -------------------------------------------------------------------------------------
  Method            Endpoint                        Access            Purpose
  ----------------- ------------------------------- ----------------- -----------------
  GET               `/admin/inventory`              Admin             View variant
                                                                      stock

  PATCH             `/admin/variants/{id}/stock`    Admin             Adjust stock with
                                                                      validation

  GET               `/admin/users`                  Admin             List users

  GET               `/admin/users/{id}`             Admin             View user details

  PATCH             `/admin/users/{id}/status`      Admin             Enable/disable
                                                                      account

  GET               `/admin/dashboard/summary`      Admin             Basic sales and
                                                                      order summary

  GET               `/admin/reports/top-products`   Admin             Best-selling
                                                                      products
  -------------------------------------------------------------------------------------

Stock adjustments should validate quantity and ideally record the reason
for the change. Do not allow customers to change stock through public
endpoints.

## 12. Standard Error Response

Use a consistent error format, preferably ASP.NET Core Problem Details.

Example:

``` json
{
  "type": "about:blank",
  "title": "Validation failed",
  "status": 400,
  "detail": "One or more fields are invalid.",
  "errors": {
    "quantity": [
      "Quantity must be greater than zero."
    ]
  }
}
```

Do not return stack traces, SQL details, secrets, or internal exception
messages.

## 13. HTTP Status Codes

  Status                        Meaning
  ----------------------------- ------------------------------------------
  `200 OK`                      Request succeeded
  `201 Created`                 Resource created
  `204 No Content`              Action succeeded without a response body
  `400 Bad Request`             Invalid input
  `401 Unauthorized`            Missing or invalid authentication
  `403 Forbidden`               Authenticated but not allowed
  `404 Not Found`               Resource not found or not accessible
  `409 Conflict`                Stock, duplicate, or state conflict
  `500 Internal Server Error`   Unexpected server error

## 14. Authorization Rules

-   Public: product catalog, category listing, product reviews listing,
    registration, login.
-   Customer: own profile, addresses, cart, orders, payments, wishlist,
    and eligible reviews.
-   Admin: product/category management, inventory, order operations,
    coupon management, review moderation, user management, and reports.

The API must enforce these rules regardless of which screens the Flutter
app displays. Always derive the current user identity from validated JWT
claims and verify resource ownership in the backend.

## 15. Implementation Notes

-   Publish the API contract through Swagger/OpenAPI.
-   Use DTOs for requests and responses rather than exposing EF Core
    entities.
-   Validate all incoming data on the server.
-   Use transactions for order creation and stock updates.
-   Use decimal values for money and document VND as the currency.
-   Use consistent naming and response conventions across controllers.
-   Keep this API design proportional to the project; do not add a
    separate API gateway or distributed infrastructure.
