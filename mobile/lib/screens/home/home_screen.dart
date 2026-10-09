import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/catalog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

/// Home: search entry, categories, new arrivals and top-rated products.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = <String, IconData>{
    'running': Icons.directions_run,
    'football': Icons.sports_soccer,
    'gym': Icons.fitness_center,
    'basketball': Icons.sports_basketball,
    'sportswear': Icons.checkroom,
    'accessories': Icons.backpack_outlined,
  };

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.sports;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sport Mate', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (ref.watch(authProvider).isCustomer)
            IconButton(tooltip: 'Wishlist', onPressed: () => context.push('/wishlist'), icon: const Icon(Icons.favorite_border)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(topRatedProvider);
          await ref.read(newArrivalsProvider.future);
        },
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(user == null ? 'Find your next gear' : 'Hi ${user.fullName.split(' ').last}, ready to train?',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              hintText: 'Search shoes, boots, apparel...',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onSubmitted: (value) => context.go(Uri(path: '/shop', queryParameters: {'keyword': value.trim()}).toString()),
            ),
          ),
          SectionHeader('Shop by category', action: 'See all', onAction: () => context.go('/shop')),
          SizedBox(
            height: 104,
            child: categories.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(child: TextButton(onPressed: () => ref.invalidate(categoriesProvider), child: const Text('Retry'))),
              data: (list) => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _CategoryTile(
                  category: list[i],
                  icon: _iconFor(list[i].name),
                  onTap: () => context.go('/shop?categoryId=${list[i].id}'),
                ),
              ),
            ),
          ),
          SectionHeader('New arrivals', action: 'See all', onAction: () => context.go('/shop?sort=newest')),
          _ProductStrip(ref.watch(newArrivalsProvider), onRetry: () => ref.invalidate(newArrivalsProvider)),
          SectionHeader('Top rated', action: 'See all', onAction: () => context.go('/shop?sort=rating')),
          _ProductStrip(ref.watch(topRatedProvider), onRetry: () => ref.invalidate(topRatedProvider)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.icon, required this.onTap});

  final Category category;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 30),
          ),
          const SizedBox(height: 6),
          Text(category.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip(this.value, {required this.onRetry});

  final AsyncValue<List<ProductSummary>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 300,
        child: AsyncValueView(
          value: value,
          onRetry: onRetry,
          data: (products) => products.isEmpty
              ? const EmptyView(message: 'No products yet.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: 170, child: ProductCard(products[i])),
                ),
        ),
      );
}
