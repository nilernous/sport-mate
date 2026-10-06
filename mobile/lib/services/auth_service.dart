import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/common.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResult> login(String email, String password) async =>
      AuthResult.fromJson(await _api.post<Json>(ApiEndpoints.login, data: {'email': email.trim(), 'password': password}));

  Future<AuthResult> register({required String fullName, required String email, required String password, String? phoneNumber}) async =>
      AuthResult.fromJson(await _api.post<Json>(ApiEndpoints.register, data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'phoneNumber': phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
      }));

  Future<void> logout() => _api.post<void>(ApiEndpoints.logout);

  Future<String> forgotPassword(String email) async =>
      '${(await _api.post<Json>(ApiEndpoints.forgotPassword, data: {'email': email.trim()}))['message']}';

  Future<String> resetPassword(String token, String newPassword) async =>
      '${(await _api.post<Json>(ApiEndpoints.resetPassword, data: {'token': token.trim(), 'newPassword': newPassword}))['message']}';

  Future<AppUser> me() async => AppUser.fromJson(await _api.get<Json>(ApiEndpoints.me));
}

final authServiceProvider = Provider((ref) => AuthService(ref.watch(apiClientProvider)));
