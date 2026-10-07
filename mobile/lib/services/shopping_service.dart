import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/common.dart';
import '../models/user.dart';

class AddressService {
  AddressService(this._api);

  final ApiClient _api;

  Future<List<Address>> list() async =>
      (await _api.get<List<dynamic>>(ApiEndpoints.myAddresses)).map((e) => Address.fromJson(e as Json)).toList();

  Future<Address> create(Json data) async => Address.fromJson(await _api.post<Json>(ApiEndpoints.myAddresses, data: data));
}

final addressServiceProvider = Provider((ref) => AddressService(ref.watch(apiClientProvider)));
