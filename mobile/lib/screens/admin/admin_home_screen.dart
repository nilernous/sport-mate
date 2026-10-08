import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class _AdminItem {
  const _AdminItem(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

/// Admin Panel entry, shared by Staff and Admin. The API rejects anything a role may not do.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static const _items = [
    _AdminItem(Icons.category_outlined, 'Categories & brands', 'Organise the catalog', '/admin/catalog-setup'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(auth.isAdmin ? 'Admin Panel' : 'Staff Panel')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Welcome, ${auth.user?.fullName ?? ''}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Signed in as ${auth.role?.name ?? ''}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 700 ? 3 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final item in _items)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(item.route),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(item.icon, color: theme.colorScheme.primary, size: 30),
                        const Spacer(),
                        Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ]),
                    ),
                  ),
                ),
            ],
          );
        }),
      ]),
    );
  }
}
