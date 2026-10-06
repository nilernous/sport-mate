import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/auth_screens.dart';
import '../../screens/auth/splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Routes only a signed-in Customer can open (own cart, orders, addresses, wishlist).
const _customerOnly = ['/cart', '/checkout', '/orders', '/wishlist', '/addresses'];

/// Routes for any signed-in user.
const _signedInOnly = ['/account/edit', '/account/password'];

bool _under(String location, String prefix) => location == prefix || location.startsWith('$prefix/');

/// Role-based navigation. Hiding screens is a usability measure only: the API enforces
/// every permission (BR-078).
String? _redirect(AuthState auth, GoRouterState state) {
  final location = state.matchedLocation;

  if (auth.status == AuthStatus.unknown) return location == '/splash' ? null : '/splash';

  final home = auth.isStaffOrAdmin ? '/admin' : '/home';
  if (location == '/splash') return home;

  final isAuthPage = ['/login', '/register', '/forgot-password', '/reset-password'].contains(location);
  if (auth.isLoggedIn && isAuthPage) {
    // Return to the page that asked for sign-in; later rules re-check that the role may open it.
    final from = state.uri.queryParameters['from'];
    return from != null && from.startsWith('/') && !from.startsWith('/login') ? from : home;
  }

  final needsCustomer = _customerOnly.any((p) => _under(location, p));
  final needsLogin = needsCustomer || _signedInOnly.any((p) => _under(location, p)) || _under(location, '/admin');
  if (!auth.isLoggedIn && needsLogin) {
    return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
  }

  if (needsCustomer && !auth.isCustomer) return home;
  if (_under(location, '/admin') && !auth.isStaffOrAdmin) return '/home';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) builder) =>
      GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (_, s) => builder(s));

  int idParam(GoRouterState s, [String name = 'id']) => int.parse(s.pathParameters[name]!);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (_, state) => _redirect(ref.read(authProvider), state),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/register', builder: (_, s) => RegisterScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, s) => ResetPasswordScreen(token: s.uri.queryParameters['token'])),
    ],
  );
});
