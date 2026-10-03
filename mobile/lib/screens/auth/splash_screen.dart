import 'package:flutter/material.dart';

/// Shown while the stored session is being restored; the router moves on automatically.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sports_soccer, size: 72, color: scheme.onPrimary),
          const SizedBox(height: 16),
          Text('Sport Mate', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary)),
        ]),
      ),
    );
  }
}
