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
}
