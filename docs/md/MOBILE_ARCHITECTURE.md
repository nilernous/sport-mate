# Sport Mate --- Mobile Architecture

## 1. Overview

Sport Mate is a sports e-commerce mobile application built with
**Flutter** and **Dart**. It consumes the Sport Mate ASP.NET Core Web
API over HTTP using JSON.

The architecture is intentionally lightweight for a team project. It
separates screens, reusable widgets, API communication, models, and
state management without requiring Clean Architecture, code generation,
or a large number of abstraction layers.

## 2. Technology Stack

-   **Framework:** Flutter
-   **Language:** Dart
-   **UI:** Material 3
-   **HTTP client:** Dio
-   **Routing:** GoRouter
-   **State management:** Riverpod (use Provider instead only if the
    team has already standardized on it)
-   **Local preferences:** `shared_preferences` for non-sensitive
    preferences only
-   **Authentication:** JWT access token returned by the backend
-   **API format:** REST + JSON

Keep the selected state-management solution consistent throughout the
app. Do not mix Riverpod and Provider.

## 3. Application Structure

``` text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   │   ├── api_client.dart
│   │   └── api_endpoints.dart
│   ├── router/
│   ├── theme/
│   └── utils/
├── models/
├── services/
├── providers/
├── screens/
│   ├── auth/
│   ├── home/
│   ├── products/
│   ├── categories/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── profile/
│   ├── wishlist/
│   ├── reviews/
│   └── admin/
├── widgets/
└── main.dart
```

### Responsibilities

-   `core/`: shared configuration, API client, error types, routing,
    theme, and utility code.
-   `models/`: typed Dart models for API requests and responses.
-   `services/`: API calls grouped by domain, such as `AuthService`,
    `ProductService`, and `OrderService`.
-   `providers/`: app state and asynchronous data state.
-   `screens/`: page-level UI grouped by feature.
-   `widgets/`: reusable UI components shared by multiple screens.
-   `main.dart`: initializes the application and launches the root
    widget.

Keep feature-specific widgets near their screens when they are not
reused elsewhere. Avoid creating abstractions that have only one trivial
use.

## 4. State Management

Use state management for state that must be shared or survive widget
rebuilds.

-   **Authentication state:** current user, role, and
    signed-in/signed-out status.
-   **Cart state:** cart items and quantity changes.
-   **Catalog state:** loading, results, filters, sorting, and
    pagination.
-   **Checkout state:** selected address, shipping choice, coupon, and
    calculated totals returned by the API.
-   **Order state:** order list, order details, and status.
-   **UI state:** temporary selections, dialog state, and form
    validation.

The backend remains authoritative for product prices, discounts,
inventory, shipping fees, order totals, permissions, and payment status.
The mobile app must not treat locally calculated totals as
authoritative.

## 5. API Communication

All API communication should go through one configured Dio client.

Responsibilities of the API client:

-   Set the base URL using environment-specific configuration.
-   Set request and response timeouts.
-   Send `Accept: application/json` and `Content-Type: application/json`
    where applicable.
-   Attach `Authorization: Bearer <access-token>` to protected requests.
-   Convert network errors and API error responses into consistent app
    errors.
-   Handle `401 Unauthorized` by clearing invalid authentication state
    or performing the agreed token refresh flow, if refresh tokens are
    implemented.
-   Avoid logging credentials, tokens, or sensitive personal
    information.

Do not call Dio directly from UI widgets. Screens should call a service
or provider.

### Base URL notes

-   Android emulator: a host-machine address such as `10.0.2.2` may be
    required to reach the development computer.
-   iOS simulator: the host can commonly be reached using `localhost`,
    depending on the setup.
-   Physical device: use the development computer's reachable LAN IP or
    a configured development URL.
-   `localhost` on a physical phone refers to the phone itself, not the
    development computer.

Use HTTPS for non-local environments.

## 6. Authentication and Authorization

1.  The user submits credentials to the login endpoint.
2.  The app sends credentials to the API over HTTPS.
3.  The API validates credentials and returns an access token and the
    minimum user information needed by the app.
4.  The app attaches the token to protected API requests.
5.  On logout, the app clears its local authentication state and calls
    the backend logout/revocation endpoint if the backend supports it.

Use secure platform storage (for example, `flutter_secure_storage`) if
tokens must persist across application restarts. Do not store JWTs in
ordinary preferences or hard-code secrets in the app.

The app may hide admin-only screens for a better user experience, but
this is not a security boundary. The backend must enforce all role and
ownership checks.

## 7. Main Screens

### Customer

-   Splash / authentication
-   Home and featured products
-   Categories and product search
-   Product list and product detail
-   Cart
-   Checkout and address selection
-   Order confirmation, order history, and order detail
-   Profile and address management
-   Wishlist
-   Product reviews

### Admin

If admin functionality is included in the same Flutter application, show
the admin navigation only to users whose API-provided role indicates
`Admin`. Admin API operations must still be authorized by the backend.

-   Dashboard summary
-   Product and category management
-   Inventory management
-   Order management
-   Coupon management
-   User management
-   Review moderation

## 8. UI and Error Handling

Every API-backed screen should account for:

-   Loading state
-   Empty state
-   Success state
-   API or network error state
-   Retry where retrying is safe

Use form validation for usability, but always validate again on the
backend. Display user-friendly error messages rather than raw exception
text.

## 9. Coding Conventions

-   Use `lower_snake_case` for Dart file names.
-   Keep widgets focused and reasonably small.
-   Use typed models rather than passing unstructured maps throughout
    the UI.
-   Keep API paths in `api_endpoints.dart` or a similarly centralized
    file.
-   Keep network calls out of `build()` methods.
-   Avoid duplicating API request logic across screens.
-   Do not store prices, roles, or payment state as trusted client-side
    values.

## 10. Scope Exclusions

This project does not require a complex mobile architecture,
offline-first synchronization, micro-frontends, a separate local
database, analytics infrastructure, or advanced automated release
pipelines unless the project requirements change.

## 11. Key Design Rule

**Flutter presents the experience; ASP.NET Core owns business rules and
authorization.** The mobile app requests data and actions, while the
backend validates them and returns the authoritative result.
