import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/shopping_service.dart';

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) => ref.watch(addressServiceProvider).list());
