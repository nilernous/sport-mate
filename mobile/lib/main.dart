import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Failed requests surface to the user with a retry button instead of retrying silently.
  runApp(ProviderScope(retry: (_, _) => null, child: const SportMateApp()));
}

class SportMateApp extends ConsumerWidget {
  const SportMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Sport Mate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: ref.watch(routerProvider),
      );
}
