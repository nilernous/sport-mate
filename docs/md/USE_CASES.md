# Sport Mate --- Use Case Specification

## 1. Document Purpose

This document defines **78 individual use cases**, with exactly one use
case for each functional requirement F01--F78. Each use case has a
unique ID (`UC-001`--`UC-078`) and maps to the relevant business rules
in `BUSINESS_RULES.md`.

-   **Mobile:** Flutter
-   **Backend:** ASP.NET Core Web API
-   **Database:** SQL Server
-   **API style:** REST/JSON
-   **Authenticated roles:** `Customer`, `Staff`, `Admin`
-   **Guest:** Unauthenticated actor, not a persisted role.

The backend is authoritative for authorization, pricing, stock, orders,
payments, and data validation.

## 2. Actors

  -----------------------------------------------------------------------
  Actor                               Description
  ----------------------------------- -----------------------------------
  Guest                               Unauthenticated visitor; may
                                      register and browse/search the
                                      public catalog.

  Customer                            Registered user who manages their
                                      own profile, addresses, cart,
                                      orders, wishlist, and eligible
                                      reviews.

  Staff                               Operational user who manages
                                      catalog data, inventory, orders,
                                      manual payment confirmation, and
                                      review moderation according to
                                      assigned permissions.

  Admin                               Administrator who manages users and
                                      roles, coupons, operational
                                      settings, and reports.
  -----------------------------------------------------------------------

## 3. Use Case Diagram

This overview diagram shows actor-to-capability relationships. The
detailed specifications below define each of the 78 use cases
individually.

``` mermaid
flowchart LR
    Guest([Guest])
    Customer([Customer])
    Staff([Staff])
    Admin([Admin])

    subgraph SM[Sport Mate]
      UC01[UC-001–005 Authentication]
      UC02[UC-006–017 User and profile]
      UC03[UC-018–042 Product and catalog]
      UC04[UC-043–045 Inventory]
      UC05[UC-046–050 Cart]
      UC06[UC-051–057 Checkout and orders]
      UC07[UC-058–060 Payments]
      UC08[UC-061–067 Coupons]
      UC09[UC-068–072 Reviews]
      UC10[UC-073–075 Wishlist]
      UC11[UC-076–078 Reports]
    end

    Guest --> UC01
    Guest --> UC03
    Customer --> UC01
    Customer --> UC02
    Customer --> UC03
    Customer --> UC05
    Customer --> UC06
    Customer --> UC07
    Customer --> UC08
    Customer --> UC09
    Customer --> UC10
    Staff --> UC03
    Staff --> UC04
    Staff --> UC06
    Staff --> UC07
    Staff --> UC09
    Admin --> UC02
    Admin --> UC03
    Admin --> UC04
    Admin --> UC06
    Admin --> UC07
    Admin --> UC08
    Admin --> UC09
    Admin --> UC11
```

## 4. ID Mapping

The use cases follow the agreed functional list exactly.

  -----------------------------------------------------------------------
  Functional IDs          Use Case IDs            Area
  ----------------------- ----------------------- -----------------------
  F01--F17                UC-001--UC-017          Authentication and user
                                                  management

  F18--F42                UC-018--UC-042          Catalog, product
                                                  variants, images,
                                                  browsing

  F43--F45                UC-043--UC-045          Inventory

  F46--F50                UC-046--UC-050          Shopping cart

  F51--F57                UC-051--UC-057          Checkout and orders

  F58--F60                UC-058--UC-060          Payments

  F61--F67                UC-061--UC-067          Coupons

  F68--F72                UC-068--UC-072          Reviews

  F73--F75                UC-073--UC-075          Wishlist

  F76--F78                UC-076--UC-078          Reports
  -----------------------------------------------------------------------

## 5. Use Case Catalogue

  UC ID    Functional ID   Use case                                 Primary actor
  -------- --------------- ---------------------------------------- -------------------------------
  UC-001   F01             Register account                         Guest
  UC-002   F02             Sign in                                  Guest
  UC-003   F03             Sign out                                 Customer, Staff, Admin
  UC-004   F04             Request password reset                   Guest
  UC-005   F05             Reset password using token               Guest
  UC-006   F06             Change password                          Customer, Staff, Admin
  UC-007   F07             View own profile                         Customer, Staff, Admin
  UC-008   F08             Update own profile                       Customer, Staff, Admin
  UC-009   F09             Create delivery address                  Customer
  UC-010   F10             List own delivery addresses              Customer
  UC-011   F11             Update own delivery address              Customer
  UC-012   F12             Delete own delivery address              Customer
  UC-013   F13             Create user account                      Admin
  UC-014   F14             List and view users                      Admin
  UC-015   F15             Update user information                  Admin
  UC-016   F16             Disable user account                     Admin
  UC-017   F17             Assign or change user role               Admin
  UC-018   F18             Create category                          Staff, Admin
  UC-019   F19             List and view categories                 Staff, Admin
  UC-020   F20             Update category                          Staff, Admin
  UC-021   F21             Delete or deactivate category            Staff, Admin
  UC-022   F22             Create brand                             Staff, Admin
  UC-023   F23             List and view brands                     Staff, Admin
  UC-024   F24             Update brand                             Staff, Admin
  UC-025   F25             Delete or deactivate brand               Staff, Admin
  UC-026   F26             Create product                           Staff, Admin
  UC-027   F27             List and view products in admin          Staff, Admin
  UC-028   F28             Update product                           Staff, Admin
  UC-029   F29             Delete or deactivate product             Staff, Admin
  UC-030   F30             Create product variant                   Staff, Admin
  UC-031   F31             List and view product variants           Staff, Admin
  UC-032   F32             Update product variant                   Staff, Admin
  UC-033   F33             Delete or deactivate product variant     Staff, Admin
  UC-034   F34             Add product image                        Staff, Admin
  UC-035   F35             List product images                      Staff, Admin
  UC-036   F36             Update image metadata or display order   Staff, Admin
  UC-037   F37             Delete product image                     Staff, Admin
  UC-038   F38             Browse product list                      Guest, Customer
  UC-039   F39             View product details                     Guest, Customer
  UC-040   F40             Search products                          Guest, Customer
  UC-041   F41             Filter products                          Guest, Customer
  UC-042   F42             Sort products                            Guest, Customer
  UC-043   F43             View inventory by variant                Staff, Admin
  UC-044   F44             Adjust inventory quantity                Staff, Admin
  UC-045   F45             View inventory movement history          Staff, Admin
  UC-046   F46             View own cart                            Customer
  UC-047   F47             Add item to cart                         Customer
  UC-048   F48             Update cart item quantity                Customer
  UC-049   F49             Remove item from cart                    Customer
  UC-050   F50             Clear cart                               Customer
  UC-051   F51             Preview checkout and calculate totals    Customer
  UC-052   F52             Place order                              Customer
  UC-053   F53             View own order history                   Customer
  UC-054   F54             View own order details                   Customer
  UC-055   F55             Cancel eligible own order                Customer
  UC-056   F56             Search and list all orders               Staff, Admin
  UC-057   F57             Update order status                      Staff, Admin
  UC-058   F58             View payment status for own order        Customer
  UC-059   F59             Initiate supported payment               Customer
  UC-060   F60             Confirm manual bank transfer             Staff, Admin
  UC-061   F61             Create coupon                            Admin
  UC-062   F62             List and view coupons                    Admin
  UC-063   F63             Update coupon                            Admin
  UC-064   F64             Delete or deactivate coupon              Admin
  UC-065   F65             Validate coupon code                     Customer
  UC-066   F66             Apply coupon to checkout                 Customer
  UC-067   F67             Remove coupon from checkout              Customer
  UC-068   F68             Create product review                    Customer
  UC-069   F69             View reviews                             Guest, Customer, Staff, Admin
  UC-070   F70             Update own review                        Customer
  UC-071   F71             Delete own review                        Customer
  UC-072   F72             Moderate review                          Staff, Admin
  UC-073   F73             View own wishlist                        Customer
  UC-074   F74             Add product to wishlist                  Customer
  UC-075   F75             Remove product from wishlist             Customer
  UC-076   F76             View sales and order dashboard           Admin
  UC-077   F77             View order report                        Admin
  UC-078   F78             View best-selling products report        Admin

## 6. Detailed Use Case Specifications

### UC-001 --- Register Account (F01)

-   **Primary actor:** Guest
-   **Preconditions:** Guest is not required to authenticate.
-   **Trigger:** Guest submits registration form.
-   **Main flow:**
    1.  Guest enters name, email, and password.
    2.  API validates required fields and password policy.
    3.  API checks normalized email uniqueness.
    4.  API securely hashes the password and creates a `Customer`
        account.
    5.  API returns a success response.
-   **Alternatives:** Invalid input returns `400`; duplicate email
    returns `409`.
-   **Postconditions:** A Customer account exists; plaintext password is
    never stored.
-   **Business rules:** BR-008, BR-009, BR-071, BR-072.

### UC-002 --- Sign In (F02)

-   **Primary actor:** Guest
-   **Preconditions:** Account exists and is enabled.
-   **Main flow:** Guest submits credentials; API verifies them and
    account status; API issues JWT and returns safe user information and
    role.
-   **Alternatives:** Invalid credentials return `401`; disabled account
    is rejected.
-   **Postconditions:** Client can authenticate protected requests with
    the issued token.
-   **Business rules:** BR-007, BR-006, BR-078.

### UC-003 --- Sign Out (F03)

-   **Primary actor:** Customer, Staff, Admin
-   **Preconditions:** User is authenticated.
-   **Main flow:** User requests sign out; Flutter clears local
    authentication state; API revokes refresh token/session if that
    mechanism is implemented.
-   **Alternatives:** An already-invalid session is safely cleared
    locally.
-   **Postconditions:** Local authenticated state is cleared; revocation
    occurs where supported.
-   **Business rules:** BR-078, BR-077.

### UC-004 --- Request Password Reset (F04)

-   **Primary actor:** Guest
-   **Preconditions:** None.
-   **Main flow:** Guest submits email; API returns a generic response
    and, for an eligible account, initiates a time-limited reset
    process.
-   **Alternatives:** API must not disclose whether the email exists.
-   **Postconditions:** A reset process may be initiated.
-   **Business rules:** BR-010, BR-072.

### UC-005 --- Reset Password Using Token (F05)

-   **Primary actor:** Guest
-   **Preconditions:** A valid, unused reset token is available.
-   **Main flow:** Guest submits token and new password; API validates
    token and password; API updates password hash and invalidates the
    token.
-   **Alternatives:** Expired/used token or invalid password is
    rejected.
-   **Postconditions:** Password is updated securely.
-   **Business rules:** BR-009, BR-010.

### UC-006 --- Change Password (F06)

-   **Primary actor:** Customer, Staff, Admin
-   **Preconditions:** User is authenticated.
-   **Main flow:** User submits current and new password; API verifies
    current password, validates new password, updates hash, and follows
    the configured session-revocation policy.
-   **Alternatives:** Incorrect current password or invalid new password
    is rejected.
-   **Postconditions:** Password is changed.
-   **Business rules:** BR-009, BR-011, BR-078.

### UC-007 --- View Own Profile (F07)

-   **Primary actor:** Customer, Staff, Admin
-   **Preconditions:** User is authenticated.
-   **Main flow:** Client requests the current profile; API resolves
    user identity from validated claims and returns allowed fields.
-   **Alternatives:** Invalid token returns `401`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-006, BR-011, BR-078.

### UC-008 --- Update Own Profile (F08)

-   **Primary actor:** Customer, Staff, Admin
-   **Preconditions:** User is authenticated.
-   **Main flow:** User submits allowed profile fields; API validates
    and updates only the current user's record.
-   **Alternatives:** Invalid fields return `400`; attempts to update
    role/status through this endpoint are rejected or ignored.
-   **Postconditions:** Permitted profile fields are updated.
-   **Business rules:** BR-006, BR-011, BR-071.

### UC-009 --- Create Delivery Address (F09)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer submits address fields; API validates them
    and creates an address owned by the current Customer.
-   **Alternatives:** Invalid address data returns `400`.
-   **Postconditions:** New address is available to its owner.
-   **Business rules:** BR-012, BR-071.

### UC-010 --- List Own Delivery Addresses (F10)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer requests address list; API returns only
    addresses owned by the current Customer.
-   **Alternatives:** Invalid token returns `401`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-006, BR-012.

### UC-011 --- Update Own Delivery Address (F11)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and address exists.
-   **Main flow:** Customer submits address changes; API verifies
    ownership and updates permitted fields.
-   **Alternatives:** Address belongs to another user or does not exist;
    reject access.
-   **Postconditions:** Address book is updated; historical order
    address snapshots remain unchanged.
-   **Business rules:** BR-012, BR-013.

### UC-012 --- Delete Own Delivery Address (F12)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and address exists.
-   **Main flow:** Customer requests deletion; API verifies ownership
    and checks whether deletion is allowed.
-   **Alternatives:** Address is referenced by an in-progress operation
    or does not belong to the user; reject or prevent unsafe deletion.
-   **Postconditions:** Address is deleted or deactivated without
    changing historical order snapshots.
-   **Business rules:** BR-012, BR-013.

### UC-013 --- Create User Account (F13)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin submits user details and an allowed initial
    role; API validates uniqueness and role assignment and creates the
    account.
-   **Alternatives:** Duplicate email or invalid role returns an error.
-   **Postconditions:** Account is created with an allowed role.
-   **Business rules:** BR-004, BR-005, BR-008, BR-009.

### UC-014 --- List and View Users (F14)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin lists/searches users and opens a user record;
    API returns only permitted fields.
-   **Alternatives:** Invalid filters are rejected.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-005, BR-006.

### UC-015 --- Update User Information (F15)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated and target user exists.
-   **Main flow:** Admin updates permitted user information; API
    validates and persists changes.
-   **Alternatives:** Duplicate email or invalid data is rejected.
-   **Postconditions:** User record is updated.
-   **Business rules:** BR-005, BR-008, BR-071.

### UC-016 --- Disable User Account (F16)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated and target account exists.
-   **Main flow:** Admin disables the account; API updates account
    status and applies the configured session revocation behavior.
-   **Alternatives:** Attempt to disable the last active administrator
    is rejected where applicable.
-   **Postconditions:** Disabled user cannot sign in or access protected
    endpoints; historical records remain.
-   **Business rules:** BR-007, BR-005.

### UC-017 --- Assign or Change User Role (F17)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated; target user and role
    exist.
-   **Main flow:** Admin chooses an allowed role; API verifies
    authorization and persists the role change.
-   **Alternatives:** Invalid role or last-admin safeguard violation is
    rejected.
-   **Postconditions:** Role is updated and subsequent authorization
    reflects it.
-   **Business rules:** BR-004, BR-005, BR-006.

### UC-018 --- Create Category (F18)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authenticated and authorized for catalog
    management.
-   **Main flow:** Actor submits category fields; API validates and
    creates the category.
-   **Alternatives:** Missing/invalid fields or duplicate category
    key/name according to policy is rejected.
-   **Postconditions:** Category exists.
-   **Business rules:** BR-015, BR-071, BR-078.

### UC-019 --- List and View Categories (F19)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authenticated and authorized.
-   **Main flow:** Actor requests category list or a category detail;
    API returns matching records.
-   **Alternatives:** Unknown ID returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-015, BR-072.

### UC-020 --- Update Category (F20)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Category exists and actor is authorized.
-   **Main flow:** Actor submits permitted changes; API validates and
    updates category.
-   **Alternatives:** Invalid data or conflicting unique value is
    rejected.
-   **Postconditions:** Category is updated.
-   **Business rules:** BR-015, BR-071.

### UC-021 --- Delete or Deactivate Category (F21)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Category exists and actor is authorized.
-   **Main flow:** Actor requests deletion; API checks references and
    deletes only if safe, otherwise deactivates or rejects.
-   **Alternatives:** Category is referenced by products; unsafe
    physical deletion is blocked.
-   **Postconditions:** No product references are orphaned.
-   **Business rules:** BR-015, BR-020, BR-073.

### UC-022 --- Create Brand (F22)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized.
-   **Main flow:** Actor submits brand details; API validates and
    creates brand.
-   **Alternatives:** Duplicate unique brand key/name is rejected.
-   **Postconditions:** Brand exists.
-   **Business rules:** BR-015, BR-071.

### UC-023 --- List and View Brands (F23)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized.
-   **Main flow:** Actor requests brand list or detail; API returns
    results.
-   **Alternatives:** Unknown ID returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-015.

### UC-024 --- Update Brand (F24)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Brand exists.
-   **Main flow:** Actor submits changes; API validates and updates
    brand.
-   **Alternatives:** Invalid or conflicting values are rejected.
-   **Postconditions:** Brand is updated.
-   **Business rules:** BR-015, BR-071.

### UC-025 --- Delete or Deactivate Brand (F25)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Brand exists.
-   **Main flow:** Actor requests deletion; API checks product
    references and deletes only if safe, otherwise deactivates or
    rejects.
-   **Alternatives:** Referenced brand cannot be physically deleted.
-   **Postconditions:** Product references remain valid.
-   **Business rules:** BR-015, BR-020, BR-073.

### UC-026 --- Create Product (F26)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized; referenced category/brand
    exist.
-   **Main flow:** Actor submits product details; API validates fields
    and references and creates product.
-   **Alternatives:** Invalid reference or invalid price is rejected.
-   **Postconditions:** Product exists in the configured initial status.
-   **Business rules:** BR-014, BR-015, BR-018, BR-071.

### UC-027 --- List and View Products in Admin (F27)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized.
-   **Main flow:** Actor lists/searches products including
    administrative status and opens a product detail.
-   **Alternatives:** Unknown ID returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-014, BR-021.

### UC-028 --- Update Product (F28)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Product exists and actor is authorized.
-   **Main flow:** Actor edits permitted fields; API validates price,
    status, and category/brand references.
-   **Alternatives:** Invalid data or reference is rejected.
-   **Postconditions:** Product is updated; historical order snapshots
    remain unchanged.
-   **Business rules:** BR-015, BR-018, BR-039, BR-045, BR-071.

### UC-029 --- Delete or Deactivate Product (F29)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Product exists and actor is authorized.
-   **Main flow:** Actor requests deletion; API checks order references
    and related variants; delete only if safe, otherwise
    deactivate/archive.
-   **Alternatives:** Historical references prevent physical deletion.
-   **Postconditions:** Product cannot be newly purchased if
    deactivated; order history remains intact.
-   **Business rules:** BR-014, BR-020, BR-044.

### UC-030 --- Create Product Variant (F30)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Parent product exists.
-   **Main flow:** Actor submits size/color/SKU/price/stock-related
    variant details; API validates parent product, unique SKU, and
    price.
-   **Alternatives:** Duplicate SKU or invalid parent/price is rejected.
-   **Postconditions:** Variant exists and is linked to the product.
-   **Business rules:** BR-016, BR-017, BR-018, BR-022.

### UC-031 --- List and View Product Variants (F31)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized.
-   **Main flow:** Actor lists variants for a product or opens one
    variant; API returns permitted data.
-   **Alternatives:** Unknown product/variant returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-016, BR-022.

### UC-032 --- Update Product Variant (F32)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Variant exists.
-   **Main flow:** Actor updates permitted size, color, SKU, or price
    fields; API validates uniqueness and value constraints.
-   **Alternatives:** Duplicate SKU, invalid price, or unsafe stock
    mutation is rejected.
-   **Postconditions:** Variant data is updated; historical order
    snapshots remain unchanged.
-   **Business rules:** BR-016, BR-017, BR-018, BR-039, BR-045.

### UC-033 --- Delete or Deactivate Product Variant (F33)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Variant exists.
-   **Main flow:** Actor requests deletion; API checks stock and order
    references and deletes only if safe, otherwise deactivates.
-   **Alternatives:** Historical order references block physical
    deletion.
-   **Postconditions:** Inactive variant cannot be newly purchased.
-   **Business rules:** BR-014, BR-020, BR-022.

### UC-034 --- Add Product Image (F34)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Product exists; actor is authorized.
-   **Main flow:** Actor uploads or supplies an approved image
    reference; API validates file type/size and associates it with the
    product.
-   **Alternatives:** Unsupported file type, oversized file, or invalid
    product returns an error.
-   **Postconditions:** Image is associated with the product.
-   **Business rules:** BR-019, BR-071.

### UC-035 --- List Product Images (F35)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Product exists.
-   **Main flow:** Actor requests associated images; API returns image
    references and display metadata.
-   **Alternatives:** Unknown product returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-019.

### UC-036 --- Update Image Metadata or Display Order (F36)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Image exists and actor is authorized.
-   **Main flow:** Actor changes permitted metadata or display order;
    API validates and saves.
-   **Alternatives:** Invalid image reference or order value is
    rejected.
-   **Postconditions:** Image metadata is updated.
-   **Business rules:** BR-019, BR-071.

### UC-037 --- Delete Product Image (F37)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Image exists.
-   **Main flow:** Actor requests removal; API removes the product-image
    association and handles stored file cleanup according to storage
    policy.
-   **Alternatives:** Image is not associated with the product or cannot
    be safely removed; reject/report failure.
-   **Postconditions:** Image no longer appears in product gallery.
-   **Business rules:** BR-019.

### UC-038 --- Browse Product List (F38)

-   **Primary actor:** Guest, Customer
-   **Preconditions:** None.
-   **Main flow:** Actor opens catalog; API returns active public
    products with pagination.
-   **Alternatives:** Empty catalog returns an empty list.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-014, BR-021.

### UC-039 --- View Product Details (F39)

-   **Primary actor:** Guest, Customer
-   **Preconditions:** Product is public and active.
-   **Main flow:** Actor selects a product; API returns description,
    images, variants, price, and availability.
-   **Alternatives:** Missing/inactive product returns `404` or is not
    exposed.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-014, BR-016, BR-022.

### UC-040 --- Search Products (F40)

-   **Primary actor:** Guest, Customer
-   **Preconditions:** None.
-   **Main flow:** Actor submits a keyword; API searches permitted
    public fields and returns matching active products.
-   **Alternatives:** Empty keyword follows documented catalog behavior;
    invalid parameters are rejected.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-021, BR-071.

### UC-041 --- Filter Products (F41)

-   **Primary actor:** Guest, Customer
-   **Preconditions:** None.
-   **Main flow:** Actor selects category, brand, price range, size,
    and/or color filters; API validates and combines filters.
-   **Alternatives:** Invalid ranges or unsupported filter values are
    rejected.
-   **Postconditions:** Results contain only public active products.
-   **Business rules:** BR-021, BR-071.

### UC-042 --- Sort Products (F42)

-   **Primary actor:** Guest, Customer
-   **Preconditions:** None.
-   **Main flow:** Actor selects an allowed sort field and direction;
    API applies stable sorting and pagination.
-   **Alternatives:** Unknown sort field is rejected or replaced by the
    documented default.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-021.

### UC-043 --- View Inventory by Variant (F43)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authenticated and authorized.
-   **Main flow:** Actor requests inventory for a product or variant;
    API returns current available quantity.
-   **Alternatives:** Unknown variant returns `404`.
-   **Postconditions:** No stock is changed.
-   **Business rules:** BR-022, BR-026, BR-078.

### UC-044 --- Adjust Inventory Quantity (F44)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized and variant exists.
-   **Main flow:** Actor submits adjustment quantity and reason; API
    validates, updates stock safely, and records movement metadata.
-   **Alternatives:** Resulting stock would be negative or concurrent
    update conflicts; reject.
-   **Postconditions:** Stock is consistent and movement can be audited.
-   **Business rules:** BR-023, BR-025, BR-026, BR-027, BR-075, BR-076.

### UC-045 --- View Inventory Movement History (F45)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized.
-   **Main flow:** Actor filters movements by variant/date and views
    history.
-   **Alternatives:** Invalid filter returns validation error.
-   **Postconditions:** No stock is changed.
-   **Business rules:** BR-027, BR-076.

### UC-046 --- View Own Cart (F46)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer requests cart; API returns only that
    customer's items and indicative prices.
-   **Alternatives:** Empty cart returns an empty list.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-029, BR-031.

### UC-047 --- Add Item to Cart (F47)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated; variant is active.
-   **Main flow:** Customer submits variant ID and positive quantity;
    API validates purchasability and updates/creates cart item.
-   **Alternatives:** Invalid/inactive variant or invalid quantity is
    rejected; stock shortage is reported.
-   **Postconditions:** Current customer's cart contains the item.
-   **Business rules:** BR-022, BR-029, BR-030, BR-024.

### UC-048 --- Update Cart Item Quantity (F48)

-   **Primary actor:** Customer
-   **Preconditions:** Cart item belongs to current Customer.
-   **Main flow:** Customer submits new positive quantity; API verifies
    ownership and current product availability.
-   **Alternatives:** Item belongs to another user, invalid quantity, or
    insufficient stock; reject.
-   **Postconditions:** Cart quantity is updated.
-   **Business rules:** BR-029, BR-030, BR-024.

### UC-049 --- Remove Item from Cart (F49)

-   **Primary actor:** Customer
-   **Preconditions:** Cart item belongs to current Customer.
-   **Main flow:** Customer requests removal; API verifies ownership and
    removes item.
-   **Alternatives:** Unknown/non-owned item is rejected or returns not
    found.
-   **Postconditions:** Item is removed from own cart.
-   **Business rules:** BR-029.

### UC-050 --- Clear Cart (F50)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer requests clear; API removes all items from
    the current customer's cart.
-   **Alternatives:** Empty cart succeeds as a no-op.
-   **Postconditions:** Current customer's cart is empty.
-   **Business rules:** BR-029.

### UC-051 --- Preview Checkout and Calculate Totals (F51)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer selects address, shipping method, and
    optional coupon; API verifies address ownership, current prices,
    stock, shipping choice, and coupon; API returns subtotal, discount,
    shipping, and estimated total.
-   **Alternatives:** Invalid address, unavailable item, invalid coupon,
    or unsupported shipping method returns a validation/conflict
    response.
-   **Postconditions:** Preview is returned; no order is committed.
-   **Business rules:** BR-031--BR-035, BR-056, BR-058.

### UC-052 --- Place Order (F52)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and checkout data is
    valid.
-   **Main flow:** API reloads authoritative prices and stock; validates
    address, coupon, and payment method; calculates totals; creates
    order and item snapshots; updates/reserves stock and records coupon
    usage in a transaction; returns order reference.
-   **Alternatives:** Stock/coupon/address/payment validation fails; no
    partial order or inconsistent stock/usage is left. Duplicate retry
    is handled by the agreed idempotency strategy.
-   **Postconditions:** Order, inventory, cart, coupon, and payment
    records are consistent.
-   **Business rules:** BR-024, BR-025, BR-033--BR-039, BR-045,
    BR-058--BR-059, BR-074--BR-075.

### UC-053 --- View Own Order History (F53)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer requests order list; API returns only orders
    owned by the current user, with pagination if needed.
-   **Alternatives:** No orders returns an empty list.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-038, BR-044.

### UC-054 --- View Own Order Details (F54)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and order exists.
-   **Main flow:** Customer requests order details; API checks ownership
    and returns item snapshots, totals, delivery snapshot, order status,
    and permitted payment status.
-   **Alternatives:** Another user's order is not disclosed.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-013, BR-038, BR-039, BR-046.

### UC-055 --- Cancel Eligible Own Order (F55)

-   **Primary actor:** Customer
-   **Preconditions:** Customer owns the order and its status is
    cancellable.
-   **Main flow:** Customer requests cancellation; API validates state,
    records cancellation, and restores/releases inventory exactly once;
    payment/refund state is handled according to policy.
-   **Alternatives:** Order passed cancellation cutoff or concurrent
    state changed; reject with conflict.
-   **Postconditions:** Order and inventory remain consistent.
-   **Business rules:** BR-028, BR-038, BR-040--BR-045, BR-053,
    BR-074--BR-075.

### UC-056 --- Search and List All Orders (F56)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authenticated and authorized for order
    operations.
-   **Main flow:** Actor searches/filters orders by identifier, status,
    customer, or date; API returns permitted results.
-   **Alternatives:** Invalid filters are rejected.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-038, BR-043, BR-072.

### UC-057 --- Update Order Status (F57)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized and order exists.
-   **Main flow:** Actor selects next status; API verifies the
    transition and associated payment/inventory conditions, then saves
    the state change and actor/time.
-   **Alternatives:** Invalid transition or concurrent update returns
    conflict.
-   **Postconditions:** Order is in a permitted state and sensitive
    action is auditable.
-   **Business rules:** BR-040--BR-044, BR-046, BR-076.

### UC-058 --- View Payment Status for Own Order (F58)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and owns the order.
-   **Main flow:** Customer requests payment status; API checks
    ownership and returns payment method, amount, and allowed status
    details.
-   **Alternatives:** Order belongs to another user; reject/not found.
-   **Postconditions:** No payment state is changed.
-   **Business rules:** BR-038, BR-046, BR-052.

### UC-059 --- Initiate Supported Payment (F59)

-   **Primary actor:** Customer
-   **Preconditions:** Customer owns the order and its state permits
    payment.
-   **Main flow:** Customer chooses COD or supported bank-transfer
    instructions; API validates the method and returns payment
    instructions/record or gateway initiation if a provider is
    explicitly integrated.
-   **Alternatives:** Unsupported method or ineligible order is
    rejected.
-   **Postconditions:** Payment is pending or follows the defined COD
    flow; it is not marked paid merely by client assertion.
-   **Business rules:** BR-046--BR-049, BR-052.

### UC-060 --- Confirm Manual Bank Transfer (F60)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized and payment is eligible for
    confirmation.
-   **Main flow:** Staff/Admin verifies transfer externally, confirms
    amount/reference, and submits confirmation; API validates current
    state and records confirmer and timestamp.
-   **Alternatives:** Amount/reference mismatch, ineligible state, or
    duplicate confirmation is rejected.
-   **Postconditions:** Payment status is updated once and related order
    state follows policy.
-   **Business rules:** BR-046, BR-048, BR-050--BR-052, BR-076.

### UC-061 --- Create Coupon (F61)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin submits code, discount, validity period,
    eligibility and usage limits; API validates and creates coupon.
-   **Alternatives:** Duplicate code, invalid dates, negative discount,
    or invalid limits are rejected.
-   **Postconditions:** Coupon exists in the configured status.
-   **Business rules:** BR-054--BR-057, BR-071.

### UC-062 --- List and View Coupons (F62)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin lists/searches coupons and opens a coupon
    detail.
-   **Alternatives:** Unknown ID returns `404`.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-054--BR-056.

### UC-063 --- Update Coupon (F63)

-   **Primary actor:** Admin
-   **Preconditions:** Coupon exists.
-   **Main flow:** Admin updates allowed coupon fields; API validates
    code uniqueness, dates, discount, and limits.
-   **Alternatives:** Invalid values or duplicate code are rejected.
-   **Postconditions:** Coupon rules are updated without changing
    existing order snapshots.
-   **Business rules:** BR-054--BR-057, BR-060.

### UC-064 --- Delete or Deactivate Coupon (F64)

-   **Primary actor:** Admin
-   **Preconditions:** Coupon exists.
-   **Main flow:** Admin requests deletion/deactivation; API disables it
    or deletes only if safe.
-   **Alternatives:** Historical coupon usage may require deactivation
    instead of physical deletion.
-   **Postconditions:** Coupon cannot be applied when disabled;
    historical orders remain intact.
-   **Business rules:** BR-055, BR-059, BR-060.

### UC-065 --- Validate Coupon Code (F65)

-   **Primary actor:** Customer
-   **Preconditions:** Customer has a cart/checkout context.
-   **Main flow:** Customer submits code; API checks enabled status,
    date window, minimum order, eligible products, and usage limits;
    returns validity and a safe reason.
-   **Alternatives:** Expired, exhausted, or ineligible coupon is
    rejected.
-   **Postconditions:** No usage is consumed by validation alone.
-   **Business rules:** BR-055--BR-059.

### UC-066 --- Apply Coupon to Checkout (F66)

-   **Primary actor:** Customer
-   **Preconditions:** Coupon passed validation for current checkout.
-   **Main flow:** Customer selects the coupon; API recalculates
    discount and estimated total. Coupon is revalidated during order
    creation.
-   **Alternatives:** Cart changed or coupon no longer eligible;
    application is rejected or removed.
-   **Postconditions:** Preview reflects the eligible discount; usage is
    committed only with the order.
-   **Business rules:** BR-033, BR-056--BR-059.

### UC-067 --- Remove Coupon from Checkout (F67)

-   **Primary actor:** Customer
-   **Preconditions:** Coupon is applied to checkout preview.
-   **Main flow:** Customer removes coupon; API recalculates totals
    without the coupon.
-   **Alternatives:** No coupon is applied; operation succeeds as a
    no-op.
-   **Postconditions:** No coupon usage is consumed.
-   **Business rules:** BR-033, BR-059.

### UC-068 --- Create Product Review (F68)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated and meets review
    eligibility policy.
-   **Main flow:** Customer submits product, rating, and review text;
    API validates purchase eligibility, rating range, text, and
    duplicate policy; review is created.
-   **Alternatives:** Ineligible purchase, invalid rating, or prohibited
    duplicate is rejected.
-   **Postconditions:** Review is stored with owner and moderation
    status.
-   **Business rules:** BR-061, BR-063--BR-065, BR-071.

### UC-069 --- View Reviews (F69)

-   **Primary actor:** Guest, Customer, Staff, Admin
-   **Preconditions:** Public listing requires no authentication;
    administrative view requires appropriate authorization.
-   **Main flow:** Actor requests product reviews or permitted review
    details; API returns only reviews visible to that actor.
-   **Alternatives:** Hidden/rejected reviews are excluded from public
    results.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-065, BR-072.

### UC-070 --- Update Own Review (F70)

-   **Primary actor:** Customer
-   **Preconditions:** Customer owns the review and editing is allowed.
-   **Main flow:** Customer updates rating/text; API verifies ownership,
    validates fields, and saves changes.
-   **Alternatives:** Review belongs to another user or moderation
    policy prevents editing; reject.
-   **Postconditions:** Review is updated and moderation state follows
    policy.
-   **Business rules:** BR-062--BR-065.

### UC-071 --- Delete Own Review (F71)

-   **Primary actor:** Customer
-   **Preconditions:** Customer owns the review.
-   **Main flow:** Customer requests deletion; API verifies ownership
    and deletes or soft-deletes according to policy.
-   **Alternatives:** Review belongs to another user; reject/not found.
-   **Postconditions:** Review no longer appears publicly if deletion
    succeeds.
-   **Business rules:** BR-062, BR-065.

### UC-072 --- Moderate Review (F72)

-   **Primary actor:** Staff, Admin
-   **Preconditions:** Actor is authorized and review exists.
-   **Main flow:** Actor approves, hides, or rejects a review using
    allowed moderation states; API records the decision.
-   **Alternatives:** Invalid state transition is rejected.
-   **Postconditions:** Public review visibility matches moderation
    state.
-   **Business rules:** BR-005, BR-065, BR-076.

### UC-073 --- View Own Wishlist (F73)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer requests wishlist; API returns entries
    belonging to the current user.
-   **Alternatives:** Empty wishlist returns an empty list.
-   **Postconditions:** No data is changed.
-   **Business rules:** BR-066.

### UC-074 --- Add Product to Wishlist (F74)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated; product exists.
-   **Main flow:** Customer adds product; API checks product and
    prevents duplicate entry.
-   **Alternatives:** Invalid product is rejected; duplicate add follows
    documented idempotent behavior.
-   **Postconditions:** Product is in the current customer's wishlist.
-   **Business rules:** BR-066, BR-071.

### UC-075 --- Remove Product from Wishlist (F75)

-   **Primary actor:** Customer
-   **Preconditions:** Customer is authenticated.
-   **Main flow:** Customer removes a product; API verifies wishlist
    ownership and deletes the entry.
-   **Alternatives:** Missing entry is handled consistently as not found
    or no-op.
-   **Postconditions:** Product is no longer in the customer's wishlist.
-   **Business rules:** BR-066.

### UC-076 --- View Sales and Order Dashboard (F76)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin requests dashboard summary for a valid period;
    API aggregates order and revenue metrics using the documented
    definitions.
-   **Alternatives:** Invalid date range is rejected.
-   **Postconditions:** Read-only summary is returned.
-   **Business rules:** BR-067--BR-069.

### UC-077 --- View Order Report (F77)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin selects a date range/status filter; API returns
    order counts and summary grouped by the requested dimension.
-   **Alternatives:** Invalid range or filter is rejected.
-   **Postconditions:** Read-only report is returned.
-   **Business rules:** BR-067--BR-069.

### UC-078 --- View Best-Selling Products Report (F78)

-   **Primary actor:** Admin
-   **Preconditions:** Admin is authenticated.
-   **Main flow:** Admin requests best-selling products for a period;
    API ranks products using the agreed quantity/revenue definition.
-   **Alternatives:** Invalid date range is rejected; no matching orders
    returns an empty result.
-   **Postconditions:** Read-only report is returned.
-   **Business rules:** BR-067, BR-069, BR-070.

## 7. Authorization Summary

  -----------------------------------------------------------------------------------
  Capability                       Guest       Customer          Staff          Admin
  ----------------------- -------------- -------------- -------------- --------------
  Browse public catalog              Yes            Yes            Yes            Yes

  Manage own profile                  No            Yes            Yes            Yes

  Manage own                          No            Yes  No by default  No by default
  addresses/cart/orders                                                

  Manage catalog and                  No             No            Yes            Yes
  inventory                                                            

  Process all orders                  No             No            Yes            Yes

  Confirm manual bank                 No             No            Yes            Yes
  transfer                                                             

  Manage coupons                      No             No             No            Yes

  Manage users and roles              No             No             No            Yes

  View reports                        No             No             No            Yes

  Moderate reviews                    No             No            Yes            Yes
  -----------------------------------------------------------------------------------

## 8. Cross-Cutting Acceptance Criteria

-   All protected endpoints require a valid JWT.
-   Role and resource ownership checks are enforced by ASP.NET Core API.
-   Business-relevant input is validated server-side.
-   Order totals are calculated on the server.
-   Order creation, inventory changes, and coupon usage remain
    consistent on failure.
-   Errors use consistent HTTP status codes and response format.
-   Passwords, signing keys, and sensitive data are not exposed in
    responses or logs.
-   The 78 functional IDs F01--F78 map one-to-one to UC-001--UC-078.
