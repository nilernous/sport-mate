import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/catalog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/shopping_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Product detail with images, variant selection, add to cart and wishlist (UC-039, UC-047, UC-074).
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _color;
  String? _size;
  int _quantity = 1;
  int _imageIndex = 0;

  Variant? _selected(ProductDetail p) {
    if (_color == null || _size == null) return null;
    for (final v in p.variants) {
      if (v.color == _color && v.size == _size) return v;
    }
    return null;
  }

  void _requireLogin() => context.push('/login?from=${Uri.encodeComponent('/products/${widget.productId}')}');

  Future<void> _addToCart(ProductDetail p, {bool buyNow = false}) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return _requireLogin();
    final variant = _selected(p);
    if (variant == null) {
      showMessage(context, 'Please choose a color and size.');
      return;
    }
    final ok = await runGuarded(context, () => ref.read(cartProvider.notifier).add(variant.id, _quantity),
        success: buyNow ? null : 'Added to cart');
    if (ok && buyNow && mounted) context.go('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!auth.isStaffOrAdmin)
            Consumer(builder: (context, ref, _) {
              final liked = ref.watch(isWishlistedProvider(widget.productId));
              return IconButton(
                tooltip: liked ? 'Remove from wishlist' : 'Add to wishlist',
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
                onPressed: () {
                  if (!auth.isLoggedIn) return _requireLogin();
                  runGuarded(context, () => ref.read(wishlistProvider.notifier).toggle(widget.productId),
                      success: liked ? 'Removed from wishlist' : 'Saved to wishlist');
                },
              );
            }),
          if (auth.isStaffOrAdmin)
            IconButton(tooltip: 'Edit product', icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/admin/products/${widget.productId}')),
        ],
      ),
      body: AsyncValueView(
        value: product,
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        data: (p) => _buildBody(context, p),
      ),
      bottomNavigationBar: product.value == null || auth.isStaffOrAdmin ? null : _buildBottomBar(product.value!),
    );
  }

  Widget _buildBody(BuildContext context, ProductDetail p) {
    final theme = Theme.of(context);
    final colors = p.colors;
    _color ??= colors.isNotEmpty ? colors.first : null;
    final sizes = p.variants.where((v) => v.color == _color).toList();
    final variant = _selected(p);

    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      AspectRatio(
        aspectRatio: 1,
        child: Stack(children: [
          PageView.builder(
            itemCount: p.images.isEmpty ? 1 : p.images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => AppImage(p.images.isEmpty ? null : p.images[i].url, borderRadius: 0),
          ),
          if (p.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < p.images.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _imageIndex ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: i == _imageIndex ? 1 : 0.6), borderRadius: BorderRadius.circular(4)),
                  ),
              ]),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p.brandName} · ${p.categoryName}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            RatingStars(p.averageRating),
            const SizedBox(width: 6),
            Text(p.reviewCount == 0 ? 'No reviews yet' : '${p.averageRating.toStringAsFixed(1)} (${p.reviewCount} reviews)'),
          ]),
          const SizedBox(height: 12),
          Text(formatVnd(variant?.price ?? p.price), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
          if (p.variants.isEmpty) ...[
            const SizedBox(height: 16),
            const Text('This product is currently unavailable.'),
          ] else ...[
            const SizedBox(height: 20),
            Text('Color: ${_color ?? ''}', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in colors)
                ChoiceChip(
                  label: Text(c),
                  selected: c == _color,
                  onSelected: (_) => setState(() {
                    _color = c;
                    if (!p.variants.any((v) => v.color == c && v.size == _size)) _size = null;
                    _quantity = 1;
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Size', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in sizes)
                ChoiceChip(
                  label: Text(v.size, style: v.inStock ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
                  selected: v.size == _size,
                  onSelected: v.inStock ? (_) => setState(() {
                        _size = v.size;
                        _quantity = 1;
                      }) : null,
                ),
            ]),
            const SizedBox(height: 12),
            if (variant != null)
              Row(children: [
                QuantityStepper(value: _quantity, max: variant.stockQuantity.clamp(1, 99), onChanged: (q) => setState(() => _quantity = q)),
                const SizedBox(width: 12),
                Text(variant.stockQuantity <= 5 ? 'Only ${variant.stockQuantity} left' : 'In stock',
                    style: TextStyle(color: variant.stockQuantity <= 5 ? Colors.orange.shade800 : Colors.green.shade700)),
              ]),
          ],
          if ((p.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(p.description!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildBottomBar(ProductDetail p) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Expanded(child: BusyButton(label: 'Add to cart', icon: Icons.add_shopping_cart, outlined: true, onPressed: p.variants.isEmpty ? null : () => _addToCart(p))),
            const SizedBox(width: 12),
            Expanded(child: BusyButton(label: 'Buy now', onPressed: p.variants.isEmpty ? null : () => _addToCart(p, buyNow: true))),
          ]),
        ),
      );
}
