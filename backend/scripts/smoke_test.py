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
call("GET", "/admin/products", cust, expect=403)
call("GET", "/admin/products", staff, expect=200)
call("GET", "/admin/products", admin, expect=200)
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
r, v = call("POST", f"/admin/products/{pid}/variants", staff, json={"sku": sku, "size": "42", "color": "Red", "price": 150000, "initialStock": 5}, expect=201)
call("POST", f"/admin/products/{pid}/variants", staff, json={"sku": sku.lower(), "size": "43", "color": "Red", "price": 1, "initialStock": 0}, expect=409)
def stock():
    detail = call("GET", f"/admin/products/{pid}", staff)[1]
    return next(x for x in detail["variants"] if x["id"] == v["id"])["stockQuantity"]


check("initial stock", stock() == 5, stock())

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
r, pv = call("POST", "/checkout/preview", cust, json={"addressId": other_addr["id"], "shippingMethod": "Standard"}, expect=200)
check("foreign address rejected", not pv["canPlaceOrder"], pv["problems"])
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
check("stock deducted", stock() == 2, stock())
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
check("stock zero not negative", stock() == 0, stock())

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

# --- Error shape ---
r, err = call("GET", "/admin/products", cust, expect=403)
print("403 body:", r.text[:200])
r, err = call("GET", "/products/999999", expect=404)
check("problem details", err and err.get("status") == 404 and "title" in err, err)

print(f"\n{passed} checks passed, {len(failures)} failed")
for f in failures:
    print(" -", f)
sys.exit(1 if failures else 0)
