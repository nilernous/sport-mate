"""End-to-end smoke test for the Sport Mate API.

Run against a freshly seeded Development database: python scripts/smoke_test.py
Requires: pip install requests
"""
import sys
import uuid
import threading
import requests

BASE = "http://localhost:5005/api/v1"
failures = []
passed = 0


def check(name, cond, info=""):
    global passed
    if cond:
        passed += 1
    else:
        failures.append(f"{name}: {info}")
        print("FAIL", name, info)


def call(method, path, token=None, expect=None, **kw):
    headers = kw.pop("headers", {})
    if token:
        headers["Authorization"] = f"Bearer {token}"
    r = requests.request(method, BASE + path, headers=headers, timeout=30, **kw)
    if expect is not None:
        check(f"{method} {path} -> {expect}", r.status_code == expect, f"got {r.status_code} {r.text[:300]}")
    try:
        return r, r.json()
    except Exception:
        return r, None


def login(email, pw):
    r, body = call("POST", "/auth/login", json={"email": email, "password": pw}, expect=200)
    return body["accessToken"], body["user"]


admin, _ = login("admin@sportmate.vn", "Admin@123")
staff, _ = login("staff@sportmate.vn", "Staff@123")
cust, cust_user = login("customer@sportmate.vn", "Customer@123")
check("role in login", cust_user["role"] == "Customer", cust_user)

# --- Auth ---
call("POST", "/auth/login", json={"email": "customer@sportmate.vn", "password": "wrong1234"}, expect=401)
email = f"new{uuid.uuid4().hex[:6]}@test.vn"
r, reg = call("POST", "/auth/register", json={"fullName": "New User", "email": email, "password": "abc12345"}, expect=201)
call("POST", "/auth/register", json={"fullName": "Dup", "email": email.upper(), "password": "abc12345"}, expect=409)
call("POST", "/auth/register", json={"fullName": "Weak", "email": "w@test.vn", "password": "short"}, expect=400)
newtok = reg["accessToken"]
call("GET", "/users/me", newtok, expect=200)
r, prof = call("PUT", "/users/me", newtok, json={"fullName": "New User 2", "phoneNumber": "0912345678"}, expect=200)
check("profile updated", prof["fullName"] == "New User 2")
r, cp = call("PUT", "/users/me/password", newtok, json={"currentPassword": "abc12345", "newPassword": "xyz98765"}, expect=200)
call("GET", "/users/me", newtok, expect=401)  # old token revoked
newtok = cp["accessToken"]
call("GET", "/users/me", newtok, expect=200)
call("POST", "/auth/logout", newtok, expect=204)
call("GET", "/users/me", newtok, expect=401)
call("POST", "/auth/forgot-password", json={"email": "nobody@x.vn"}, expect=200)
call("POST", "/auth/reset-password", json={"token": "bad", "newPassword": "abc12345"}, expect=400)
call("GET", "/users/me", expect=401)

# --- Authorization boundaries ---
call("GET", "/admin/coupons", staff, expect=403)
call("GET", "/admin/orders", cust, expect=403)
call("GET", "/admin/orders", staff, expect=200)
call("GET", "/cart", staff, expect=403)

# --- Catalog (public) ---
r, page = call("GET", "/products?pageSize=5", expect=200)
check("products listed", page["totalItems"] == 16, page.get("totalItems"))
r, page = call("GET", "/products?keyword=nike&sortBy=price&sortOrder=asc", expect=200)
prices = [p["price"] for p in page["items"]]
check("search+sort", len(prices) > 0 and prices == sorted(prices), prices)
call("GET", "/products?sortBy=hack", expect=400)
call("GET", "/products?minPrice=500&maxPrice=100", expect=400)
r, filt = call("GET", "/products/filters", expect=200)
r, page = call("GET", f"/products?categoryId={filt['categories'][0]['id']}&size=42&color=Black", expect=200)
call("GET", "/categories", expect=200)
call("GET", "/brands", expect=200)
r, prod = call("GET", f"/products/{page['items'][0]['id'] if page['items'] else 1}", expect=200)

# --- Admin catalog ---
r, cat = call("POST", "/admin/categories", staff, json={"name": "Test Cat " + uuid.uuid4().hex[:4]}, expect=201)
call("POST", "/admin/categories", staff, json={"name": cat["name"].upper()}, expect=409)
r, brand = call("POST", "/admin/brands", staff, json={"name": "Test Brand " + uuid.uuid4().hex[:4]}, expect=201)
r, p = call("POST", "/admin/products", staff, json={"name": "Test Shoe", "categoryId": cat["id"], "brandId": brand["id"], "basePrice": 100000}, expect=201)
pid = p["id"]
call("POST", "/admin/products", staff, json={"name": "Bad", "categoryId": 99999, "brandId": brand["id"], "basePrice": 1}, expect=400)
sku = "TST-" + uuid.uuid4().hex[:6]
r, v = call("POST", f"/admin/products/{pid}/variants", staff, json={"sku": sku, "size": "42", "color": "Red", "price": 120000, "initialStock": 2}, expect=201)
call("POST", f"/admin/products/{pid}/variants", staff, json={"sku": sku.lower(), "size": "43", "color": "Red", "price": 1, "initialStock": 0}, expect=409)
call("PUT", f"/admin/variants/{v['id']}", staff, json={"sku": sku, "size": "42", "color": "Red", "price": 150000, "isActive": True}, expect=200)

# --- Inventory ---
call("PATCH", f"/admin/variants/{v['id']}/stock", staff, json={"quantityChange": -5, "reason": "Damaged"}, expect=409)
r, inv = call("PATCH", f"/admin/variants/{v['id']}/stock", staff, json={"quantityChange": 3, "reason": "Restock"}, expect=200)
check("stock adjusted", inv["stockQuantity"] == 5, inv)
r, mv = call("GET", f"/admin/inventory/movements?variantId={v['id']}", staff, expect=200)
check("movements", mv["totalItems"] == 2, mv["totalItems"])
call("GET", "/admin/inventory?maxStock=3", staff, expect=200)

# --- Cart ---
call("DELETE", "/cart", cust, expect=204)
call("POST", "/cart/items", cust, json={"variantId": v["id"], "quantity": 99}, expect=409)
r, cart = call("POST", "/cart/items", cust, json={"variantId": v["id"], "quantity": 2}, expect=200)
check("cart total", cart["estimatedSubtotal"] == 300000, cart)
item_id = cart["items"][0]["id"]
call("PATCH", f"/cart/items/{item_id}", cust, json={"quantity": 3}, expect=200)
# another customer's item
other, _ = login(email, "xyz98765")
call("PATCH", f"/cart/items/{item_id}", other, json={"quantity": 1}, expect=404)

# --- Checkout ---
r, addrs = call("GET", "/users/me/addresses", cust, expect=200)
addr_id = addrs[0]["id"]
r, other_addr = call("POST", "/users/me/addresses", other, json={"recipientName": "O", "phoneNumber": "0900000000", "addressLine": "1 A", "ward": "W", "district": "D", "city": "C"}, expect=201)
r, pv = call("POST", "/checkout/preview", cust, json={"addressId": addr_id, "shippingMethod": "Standard"}, expect=200)
check("preview totals", pv["subtotal"] == 450000 and pv["shippingFee"] == 30000 and pv["total"] == 480000, pv)
r, pv = call("POST", "/checkout/preview", cust, json={"addressId": addr_id, "shippingMethod": "Standard", "couponCode": "WELCOME10"}, expect=200)
check("coupon min order rejected", pv["coupon"]["isValid"] is False and not pv["canPlaceOrder"], pv["coupon"])
r, vc = call("POST", "/coupons/validate", cust, json={"code": "EXPIRED20"}, expect=200)
check("expired coupon", vc["isValid"] is False, vc)
call("POST", "/orders", cust, json={"addressId": other_addr["id"], "shippingMethod": "Standard", "paymentMethod": "COD"}, expect=400)
# Client-sent totals are ignored
key = uuid.uuid4().hex
r, order = call("POST", "/orders", cust, headers={"Idempotency-Key": key},
                json={"addressId": addr_id, "shippingMethod": "Express", "paymentMethod": "BankTransfer", "totalAmount": 1}, expect=201)
check("order total server-side", order["totalAmount"] == 500000, order.get("totalAmount"))
check("bank instructions", order["payment"]["bankTransferInstructions"]["transferContent"] == order["orderCode"], order["payment"])
r, order_again = call("POST", "/orders", cust, headers={"Idempotency-Key": key},
                      json={"addressId": addr_id, "shippingMethod": "Express", "paymentMethod": "BankTransfer"}, expect=200)
check("idempotent", order_again["id"] == order["id"])
r, cart = call("GET", "/cart", cust, expect=200)
check("cart cleared", len(cart["items"]) == 0, cart)
r, inv = call("GET", f"/admin/inventory?variantId={v['id']}", staff, expect=200)
check("stock deducted", inv["items"][0]["stockQuantity"] == 2, inv["items"][0])
call("GET", f"/orders/{order['id']}", other, expect=404)
call("POST", "/orders", cust, json={"addressId": addr_id, "shippingMethod": "Standard", "paymentMethod": "COD"}, expect=409)  # empty cart

# --- Concurrency: two customers race for the last 2 units ---
call("POST", "/cart/items", cust, json={"variantId": v["id"], "quantity": 2}, expect=200)
call("POST", "/cart/items", other, json={"variantId": v["id"], "quantity": 2}, expect=200)
results = {}
def place(tok, addr, name):
    results[name] = requests.post(BASE + "/orders", headers={"Authorization": f"Bearer {tok}"},
                                  json={"addressId": addr, "shippingMethod": "Standard", "paymentMethod": "COD"}).status_code
t1 = threading.Thread(target=place, args=(cust, addr_id, "a")); t2 = threading.Thread(target=place, args=(other, other_addr["id"], "b"))
t1.start(); t2.start(); t1.join(); t2.join()
check("no oversell", sorted(results.values()) == [201, 409], results)
r, inv = call("GET", f"/admin/inventory?variantId={v['id']}", staff, expect=200)
check("stock zero not negative", inv["items"][0]["stockQuantity"] == 0, inv["items"][0])

# --- Payments & order status ---
pay_id = order["payment"]["id"]
call("POST", f"/orders/{order['id']}/payment", cust, json={"method": "COD"}, expect=200)
call("POST", f"/orders/{order['id']}/payment", cust, json={"method": "BankTransfer"}, expect=200)
call("PATCH", f"/admin/orders/{order['id']}/status", staff, json={"status": "Shipping"}, expect=409)  # invalid transition
call("PATCH", f"/admin/payments/{pay_id}/confirm", staff, json={"amount": 1, "transferReference": order["orderCode"]}, expect=400)
r, paid = call("PATCH", f"/admin/payments/{pay_id}/confirm", staff, json={"amount": 500000, "transferReference": order["orderCode"]}, expect=200)
check("paid", paid["status"] == "Paid" and paid["confirmedBy"], paid)
call("PATCH", f"/admin/payments/{pay_id}/confirm", staff, json={"amount": 500000, "transferReference": order["orderCode"]}, expect=409)
r, od = call("GET", f"/orders/{order['id']}", cust, expect=200)
check("auto-confirmed", od["status"] == "Confirmed", od["status"])
call("PATCH", f"/admin/orders/{order['id']}/status", staff, json={"status": "Shipping"}, expect=200)
call("POST", f"/orders/{order['id']}/cancel", cust, expect=409)  # shipped
r, od = call("PATCH", f"/admin/orders/{order['id']}/status", staff, json={"status": "Completed"}, expect=200)
check("history", len(od["statusHistory"]) == 4, od["statusHistory"])

# --- Cancel restores stock and coupon ---
r, prods = call("GET", "/products?keyword=Pegasus", expect=200)
pdet = call("GET", f"/products/{prods['items'][0]['id']}")[1]
var = next(x for x in pdet["variants"] if x["stockQuantity"] >= 5)
# Whoever lost the race above still has the sold-out item in their cart; start clean.
call("DELETE", "/cart", cust, expect=204)
call("POST", "/cart/items", cust, json={"variantId": var["id"], "quantity": 1}, expect=200)
r, o2 = call("POST", "/orders", cust, json={"addressId": addr_id, "shippingMethod": "Standard", "paymentMethod": "COD", "couponCode": "SALE50K"}, expect=201)
check("coupon discount", o2["discountAmount"] == 50000, o2.get("discountAmount"))
r, c = call("GET", "/admin/coupons?keyword=SALE50K", admin, expect=200)
check("coupon used", c["items"][0]["usedCount"] == 1, c["items"][0])
r, oc = call("POST", f"/orders/{o2['id']}/cancel", cust, json={"reason": "changed mind"}, expect=200)
check("cancelled", oc["status"] == "Cancelled" and oc["payment"]["status"] == "Failed", oc["status"])
call("POST", f"/orders/{o2['id']}/cancel", cust, expect=409)
r, after = call("GET", f"/products/{pdet['id']}")
var_after = next(x for x in after["variants"] if x["id"] == var["id"])
check("stock restored once", var_after["stockQuantity"] == var["stockQuantity"], (var, var_after))
r, c = call("GET", "/admin/coupons?keyword=SALE50K", admin, expect=200)
check("coupon released", c["items"][0]["usedCount"] == 0, c["items"][0])

# --- COD completion marks paid ---
r, list_ = call("GET", "/admin/orders?keyword=SMDEMO0003", staff, expect=200)
demo3 = list_["items"][0]
r, d3 = call("PATCH", f"/admin/orders/{demo3['id']}/status", staff, json={"status": "Completed"}, expect=200)
check("COD paid on delivery", d3["payment"]["status"] == "Paid", d3["payment"])

# --- Wishlist ---
call("POST", "/users/me/wishlist/items", cust, json={"productId": pid}, expect=201)
call("POST", "/users/me/wishlist/items", cust, json={"productId": pid}, expect=200)
r, wl = call("GET", "/users/me/wishlist", cust, expect=200)
check("wishlist", any(w["productId"] == pid for w in wl), wl)
call("DELETE", f"/users/me/wishlist/items/{pid}", cust, expect=204)
call("DELETE", f"/users/me/wishlist/items/{pid}", cust, expect=204)

# --- Deletes fall back to deactivation ---
r, d = call("DELETE", f"/admin/products/{pid}", staff, expect=200)
check("product deactivated", d["action"] == "Deactivated", d)
call("GET", f"/products/{pid}", expect=404)
r, d = call("DELETE", f"/admin/categories/{cat['id']}", staff, expect=200)
check("category deactivated", d["action"] == "Deactivated", d)
r, c2 = call("POST", "/admin/categories", staff, json={"name": "Temp " + uuid.uuid4().hex[:4]}, expect=201)
r, d = call("DELETE", f"/admin/categories/{c2['id']}", staff, expect=200)
check("category deleted", d["action"] == "Deleted", d)

# --- Coupons admin ---
code = "T" + uuid.uuid4().hex[:6].upper()
r, cp = call("POST", "/admin/coupons", admin, json={"code": code, "discountType": "Percentage", "discountValue": 150, "minOrderAmount": 0,
                                                    "startsAt": "2026-01-01T00:00:00Z", "endsAt": "2027-01-01T00:00:00Z"}, expect=400)
r, cp = call("POST", "/admin/coupons", admin, json={"code": code, "discountType": "Percentage", "discountValue": 20, "minOrderAmount": 0,
                                                    "startsAt": "2026-01-01T00:00:00Z", "endsAt": "2027-01-01T00:00:00Z"}, expect=201)
call("POST", "/admin/coupons", admin, json={"code": code.lower(), "discountType": "FixedAmount", "discountValue": 1, "minOrderAmount": 0,
                                            "startsAt": "2026-01-01T00:00:00Z", "endsAt": "2027-01-01T00:00:00Z"}, expect=409)
call("GET", f"/admin/coupons/{cp['id']}", admin, expect=200)
r, d = call("DELETE", f"/admin/coupons/{cp['id']}", admin, expect=200)
check("unused coupon deleted", d["action"] == "Deleted", d)

# --- Error shape ---
r, err = call("GET", "/admin/coupons", staff, expect=403)
print("403 body:", r.text[:200])
r, err = call("GET", "/products/999999", expect=404)
check("problem details", err and err.get("status") == 404 and "title" in err, err)

print(f"\n{passed} checks passed, {len(failures)} failed")
for f in failures:
    print(" -", f)
sys.exit(1 if failures else 0)
