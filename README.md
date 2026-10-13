# Sport Mate

Sportswear e-commerce mobile app (PRM392). Customers browse, buy and review sports gear; Staff and
Admin run the shop from an Admin Panel inside the same app.

> **This branch contains Iteration 1 only** (37 features, see `docs/specs/Sport_Mate - Features.csv`):
> authentication, own profile, adding a delivery address, catalog management (categories, brands,
> products, creating variants), browsing/search/filter/sort, cart, checkout and placing an order, and
> wishlist. Iterations 2 and 3 live on `dev`.

| Part | Stack |
|---|---|
| Mobile | Flutter · Material 3 · Riverpod · GoRouter · Dio |
| Backend | ASP.NET Core Web API (.NET 8) · EF Core 8 · JWT |
| Database | SQL Server |
| Local infra | Docker Compose (SQL Server + API) |

## Repository layout

```text
sport_mate/
├── backend/   ASP.NET Core solution: Domain, Application, Infrastructure, API (+ Dockerfile)
├── mobile/    Flutter app (customer screens + Staff/Admin panel)
├── infra/     docker-compose.yaml for the local SQL Server + API stack
└── docs/
    ├── md/    specifications: use cases, business rules, API design, architecture
    └── docx/  Sport_Mate.docx: feature list with roles and assignees
```

## Quick start

### 1. Backend with Docker (recommended)

Requires Docker Desktop.

```bash
cd infra
docker compose up -d --build
```

- API and Swagger: <http://localhost:5005/swagger>
- SQL Server: `localhost,14330`, user `sa`, password `SportMate@Dev2026`. To change it, copy
  `infra/.env.example` to `infra/.env` and edit.
- On first start the API applies the migrations and seeds demo data.
- Stop the stack with `docker compose down`. Use `docker compose down -v` to also delete the
  database and uploaded images.

### 1b. Backend without Docker

This needs the .NET 8 SDK and a local SQL Server. See [backend/README.md](backend/README.md).

```bash
cd backend/SportMate.API
dotnet run --launch-profile http
```

### 2. Mobile app

```bash
cd mobile
flutter pub get
flutter run                 # Android emulator reaches the API at 10.0.2.2:5005
flutter run -d chrome       # web, API at localhost:5005
```

For a physical phone, pass your PC's LAN address:
`--dart-define=API_BASE_URL=http://<your-ip>:5005`. See [mobile/README.md](mobile/README.md).

## Demo accounts

Created by the development seed.

| Role | Email | Password |
|---|---|---|
| Admin | `admin@sportmate.vn` | `Admin@123` |
| Staff | `staff@sportmate.vn` | `Staff@123` |
| Customer | `customer@sportmate.vn` | `Customer@123` |

## Roles

| Role | Can do |
|---|---|
| Guest | Browse, search, filter and sort products; register and sign in |
| Customer | Profile, add delivery addresses, cart, checkout (COD / bank transfer), wishlist |
| Staff | Categories, brands, products and new variants |
| Admin | Same as Staff in Iteration 1 |

Staff and Admin share the `/admin/*` API endpoints, and the app shows or hides features by role.
The API enforces every permission. Full details are in
[docs/md/USE_CASES.md](docs/md/USE_CASES.md) (F01–F78) and
[docs/md/BUSINESS_RULES.md](docs/md/BUSINESS_RULES.md).

## Checks

```bash
# Backend: end-to-end smoke test against a freshly seeded API
cd backend && pip install requests && python scripts/smoke_test.py

# Mobile
cd mobile && flutter analyze && flutter test
```
