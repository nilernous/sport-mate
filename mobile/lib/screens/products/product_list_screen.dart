import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/catalog.dart';
import '../../providers/catalog_providers.dart';
import '../../services/product_service.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/product_card.dart';

/// Browse, search, filter and sort the public catalog (UC-038, UC-040 – UC-042).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.initialCategoryId, this.initialBrandId, this.initialKeyword, this.initialSort});

  final int? initialCategoryId;
  final int? initialBrandId;
  final String? initialKeyword;
  final String? initialSort;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late ProductFilter _filter = ProductFilter(
    keyword: widget.initialKeyword,
    categoryId: widget.initialCategoryId,
    brandId: widget.initialBrandId,
    sort: ProductSort.values.firstWhere((s) => s.name == widget.initialSort, orElse: () => ProductSort.newest),
  );
  late final _search = TextEditingController(text: widget.initialKeyword);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setFilter(ProductFilter filter) => setState(() => _filter = filter);

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null) _setFilter(result);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search products',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      _setFilter(_filter.copyWith(keyword: () => null));
                    },
                  ),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) => _setFilter(_filter.copyWith(keyword: () => v.trim().isEmpty ? null : v.trim())),
        ),
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Badge(
                isLabelVisible: _filter.activeFilterCount > 0,
                label: Text('${_filter.activeFilterCount}'),
                child: ActionChip(avatar: const Icon(Icons.tune, size: 18), label: const Text('Filters'), onPressed: _openFilters),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ProductSort>(
                initialValue: _filter.sort,
                onSelected: (s) => _setFilter(_filter.copyWith(sort: s)),
                itemBuilder: (_) => [for (final s in ProductSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                child: Chip(avatar: const Icon(Icons.sort, size: 18), label: Text(_filter.sort.label)),
              ),
              const SizedBox(width: 8),
              for (final c in categories) ...[
                FilterChip(
                  label: Text(c.name),
                  selected: _filter.categoryId == c.id,
                  onSelected: (on) => _setFilter(_filter.copyWith(categoryId: () => on ? c.id : null)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: PagedListView<ProductSummary>(
            queryKey: _filter,
            fetch: (page) => ref.read(productServiceProvider).search(_filter, page: page),
            gridDelegate: productGridDelegate(context),
            emptyMessage: 'No products match your search.\nTry other keywords or clear the filters.',
            emptyIcon: Icons.search_off,
            itemBuilder: (_, product, _) => ProductCard(product),
          ),
        ),
      ]),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final ProductFilter initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductFilter _f = widget.initial;
  RangeValues? _range;

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(filterOptionsProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: options.when(
          loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(height: 240, child: Center(child: Text('$e'))),
          data: (o) {
            final maxPrice = o.maxPrice <= o.minPrice ? o.minPrice + 1 : o.maxPrice;
            _range ??= RangeValues(
              (_f.minPrice ?? o.minPrice).clamp(o.minPrice, maxPrice),
              (_f.maxPrice ?? maxPrice).clamp(o.minPrice, maxPrice),
            );
            Widget chips<T>(String title, List<T> values, T? selected, String Function(T) label, void Function(T?) onSelect) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(title, style: theme.textTheme.titleSmall)),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final v in values)
                        ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (on) => setState(() => onSelect(on ? v : null))),
                    ]),
                  ],
                );

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), children: [
                    Text('Filters', style: theme.textTheme.titleLarge),
                    chips<int>('Category', o.categories.map((c) => c.id).toList(), _f.categoryId,
                        (id) => o.categories.firstWhere((c) => c.id == id).name, (v) => _f = _f.copyWith(categoryId: () => v)),
                    chips<int>('Brand', o.brands.map((b) => b.id).toList(), _f.brandId,
                        (id) => o.brands.firstWhere((b) => b.id == id).name, (v) => _f = _f.copyWith(brandId: () => v)),
                    chips<String>('Size', o.sizes, _f.size, (s) => s, (v) => _f = _f.copyWith(size: () => v)),
                    chips<String>('Color', o.colors, _f.color, (s) => s, (v) => _f = _f.copyWith(color: () => v)),
                    Padding(padding: const EdgeInsets.only(top: 16), child: Text('Price', style: theme.textTheme.titleSmall)),
                    RangeSlider(
                      min: o.minPrice,
                      max: maxPrice,
                      divisions: 20,
                      values: _range!,
                      labels: RangeLabels(formatVnd(_range!.start), formatVnd(_range!.end)),
                      onChanged: (r) => setState(() => _range = r),
                    ),
                    Text('${formatVnd(_range!.start)} – ${formatVnd(_range!.end)}', textAlign: TextAlign.center),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, widget.initial.clearFilters()),
                        child: const Text('Clear all'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final r = _range!;
                          Navigator.pop(
                            context,
                            _f.copyWith(
                              minPrice: () => r.start <= o.minPrice ? null : r.start,
                              maxPrice: () => r.end >= maxPrice ? null : r.end,
                            ),
                          );
                        },
                        child: const Text('Show results'),
                      ),
                    ),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
