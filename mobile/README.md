# Sport Mate — Mobile (Flutter)

Flutter · Material 3 · Riverpod · GoRouter · Dio. Structure follows `docs/md/MOBILE_ARCHITECTURE.md`.

## Run

Start the backend first (see `backend/README.md`), then;

```bash
cd mobile
flutter pub get
flutter run                                   # Android emulator → http://10.0.2.2:5005
flutter run -d chrome                         # web → http://localhost:5005
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5005   # physical phone: your PC's LAN IP
```

For a physical phone, also start the API listening on the LAN:
`dotnet run --launch-profile http --urls http://0.0.0.0:5005`.

Checks: `flutter analyze` and `flutter test`.

Demo accounts: `customer@sportmate.vn` / `Customer@123`, `staff@sportmate.vn` / `Staff@123`,
`admin@sportmate.vn` / `Admin@123`.

## Structure

```text
lib/
├── core/        config, Dio client + endpoints, errors, router (role guards), theme, utils
├── models/      typed models for API DTOs
├── services/    API calls by domain (auth, products, cart/orders/addresses/wishlist, reviews, admin)
├── providers/   Riverpod state: session, cart, wishlist, catalog
├── screens/     auth, home, products, cart, checkout, orders, profile, wishlist, reviews, admin
└── widgets/     shared UI: loading/empty/error states, paged list, product card, chips
```

## Role-based UI

The role comes from the sign-in response. The app shows or hides features by role, but this is
only for usability: the API re-checks every request.

| Role     | Bottom tabs                 | Extra screens                                                        |
| -------- | --------------------------- | -------------------------------------------------------------------- |
| Guest    | Home, Shop, Cart, Account   | Cart, wishlist and checkout ask the user to sign in                  |
| Customer | Home, Shop, Cart, Account   | Orders, wishlist, addresses, reviews                                 |
| Staff    | Manage, Home, Shop, Account | Orders & payments, products, categories & brands, inventory, reviews |
| Admin    | Manage, Home, Shop, Account | Everything Staff has, plus dashboard & reports, coupons, users       |

Route guards in `core/router/app_router.dart` keep each role off pages it cannot use. For example,
Staff opening `/admin/users` are redirected to the panel.

## Notes

- The token is kept in `flutter_secure_storage`. A 401 on any request clears the session.
- Totals, discounts, shipping and stock always come from the API. The cart shows estimates and checkout uses the server preview.
- Placing an order sends an `Idempotency-Key`, so a retried tap cannot create a second order.
- Uploaded product images are returned as `/uploads/...` paths and resolved against the API origin.
