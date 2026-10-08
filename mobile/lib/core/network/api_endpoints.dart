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

  // Staff & Admin (shared /admin/* paths)
  static const adminCategories = '/admin/categories';
  static String adminCategory(int id) => '/admin/categories/$id';
  static const adminBrands = '/admin/brands';
  static String adminBrand(int id) => '/admin/brands/$id';
  static const adminProducts = '/admin/products';
  static String adminProduct(int id) => '/admin/products/$id';
  static String adminProductStatus(int id) => '/admin/products/$id/status';
  static String adminProductVariants(int id) => '/admin/products/$id/variants';
}
