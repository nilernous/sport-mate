import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/formatters.dart';
import '../models/catalog.dart';
import 'common_widgets.dart';

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});

  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(fit: StackFit.expand, children: [
              AppImage(product.imageUrl, borderRadius: 0),
              if (!product.inStock)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Sold out', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.brandName.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2)),
              const SizedBox(height: 6),
              Text(formatVnd(product.price), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (product.reviewCount > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  RatingStars(product.averageRating, size: 13),
                  const SizedBox(width: 4),
                  Text('(${product.reviewCount})', style: theme.textTheme.labelSmall),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Grid layout used by product lists; columns adapt to the screen width.
SliverGridDelegate productGridDelegate(BuildContext context) => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.62,
    );
