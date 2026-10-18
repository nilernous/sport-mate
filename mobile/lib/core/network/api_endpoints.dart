/// Every API path used by the app, relative to `/api/v1`.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';

  // Current user
  static const me = '/users/me';
  static const myPassword = '/users/me/password';
  static const myAddresses = '/users/me/addresses';
  static String myAddress(int id) => '/users/me/addresses/$id';
  static const myWishlist = '/users/me/wishlist';
  static const myWishlistItems = '/users/me/wishlist/items';
  static String myWishlistItem(int productId) => '/users/me/wishlist/items/$productId';

  // Public catalog
  static const categories = '/categories';
  static const brands = '/brands';
  static const products = '/products';
  static const productFilters = '/products/filters';
  static String product(int id) => '/products/$id';

  // Cart, checkout, orders
  static const cart = '/cart';
  static const cartItems = '/cart/items';
  static String cartItem(int id) => '/cart/items/$id';
  static const checkoutPreview = '/checkout/preview';
  static const orders = '/orders';
  static String order(int id) => '/orders/$id';
  static String cancelOrder(int id) => '/orders/$id/cancel';

  // Staff & Admin (shared /admin/* paths)
  static const adminCategories = '/admin/categories';
  static String adminCategory(int id) => '/admin/categories/$id';
  static const adminBrands = '/admin/brands';
  static String adminBrand(int id) => '/admin/brands/$id';
  static const adminProducts = '/admin/products';
  static String adminProduct(int id) => '/admin/products/$id';
  static String adminProductStatus(int id) => '/admin/products/$id/status';
  static String adminProductVariants(int id) => '/admin/products/$id/variants';
  static String adminVariant(int id) => '/admin/variants/$id';
  static String adminVariantStock(int id) => '/admin/variants/$id/stock';
  static const adminInventory = '/admin/inventory';
  static const adminInventoryMovements = '/admin/inventory/movements';
  static const adminOrders = '/admin/orders';
  static String adminOrder(int id) => '/admin/orders/$id';
  static String adminOrderStatus(int id) => '/admin/orders/$id/status';
}
