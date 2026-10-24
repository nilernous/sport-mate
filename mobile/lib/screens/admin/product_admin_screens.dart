import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/catalog.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

/// Product administration list, including inactive products (UC-027).
class AdminProductListScreen extends ConsumerStatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  ConsumerState<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends ConsumerState<AdminProductListScreen> {
  String? _keyword;
  bool? _active;
  int _version = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Products')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/admin/products/new');
            setState(() => _version++);
          },
          icon: const Icon(Icons.add),
          label: const Text('New product'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search by name, brand, category or SKU', prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              for (final option in [(null, 'All'), (true, 'Active'), (false, 'Inactive')]) ...[
                ChoiceChip(label: Text(option.$2), selected: _active == option.$1, onSelected: (_) => setState(() => _active = option.$1)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          Expanded(
            child: PagedListView<ProductSummary>(
              queryKey: (_keyword, _active, _version),
              fetch: (page) => ref.read(adminServiceProvider).products(keyword: _keyword, isActive: _active, page: page),
              emptyMessage: 'No products found.',
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              itemBuilder: (context, p, reload) => Card(
                child: ListTile(
                  leading: AppImage(p.imageUrl, width: 52, height: 52),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.brandName} · ${p.categoryName}\n${formatVnd(p.price)}${p.inStock ? '' : ' · out of stock'}'),
                  isThreeLine: true,
                  trailing: StatusChip.active(p.isActive),
                  onTap: () async {
                    await context.push('/admin/products/${p.id}');
                    reload();
                  },
                ),
              ),
            ),
          ),
        ]),
      );
}

/// Create/edit a product with its variants and images (UC-026, UC-028 – UC-037).
class AdminProductEditScreen extends ConsumerStatefulWidget {
  const AdminProductEditScreen({super.key, this.productId});

  final int? productId;

  @override
  ConsumerState<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends ConsumerState<AdminProductEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _basePrice = TextEditingController(text: '0');
  int? _categoryId;
  int? _brandId;
  bool _isActive = true;

  ProductDetail? _product;
  List<Category> _categories = const [];
  List<Brand> _brands = const [];
  Object? _error;
  bool _loading = true;

  AdminService get _service => ref.read(adminServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _basePrice.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_service.categories(), _service.brands()]);
      _categories = results[0] as List<Category>;
      _brands = results[1] as List<Brand>;
      if (widget.productId != null) _apply(await _service.product(widget.productId!));
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _apply(ProductDetail p) {
    _product = p;
    _name.text = p.name;
    _description.text = p.description ?? '';
    _basePrice.text = p.basePrice.toStringAsFixed(0);
    _categoryId = p.categoryId;
    _brandId = p.brandId;
    _isActive = p.isActive;
  }

  Future<void> _reloadProduct() async {
    final p = await _service.product(_product!.id);
    if (mounted) setState(() => _product = p);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = {
      'name': _name.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'categoryId': _categoryId,
      'brandId': _brandId,
      'basePrice': parseMoney(_basePrice.text),
      'isActive': _isActive,
    };
    await runGuarded(context, () async {
      final saved = await _service.saveProduct(_product?.id, data);
      if (!mounted) return;
      if (_product == null) {
        context.pushReplacement('/admin/products/${saved.id}');
        showMessage(context, 'Product created. Now add variants and images.');
      } else {
        setState(() => _apply(saved));
        showMessage(context, 'Product saved');
      }
    });
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context,
        title: 'Delete product',
        message: 'Products that appear in orders are deactivated instead of deleted.',
        confirmLabel: 'Delete',
        destructive: true)) {
      return;
    }
    if (!mounted) return;
    await runGuarded(context, () async {
      final result = await _service.deleteProduct(_product!.id);
      if (!mounted) return;
      showMessage(context, result.message);
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'New product' : 'Edit product'),
        actions: [
          if (product != null) ...[
            IconButton(tooltip: 'View in shop', icon: const Icon(Icons.storefront_outlined), onPressed: () => context.push('/products/${product.id}')),
            IconButton(tooltip: 'Delete product', icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(error: _error!, onRetry: _load)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => Validators.required(v, 'Name')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.isActive ? c.name : '${c.name} (inactive)'))],
                        onChanged: (v) => _categoryId = v,
                        validator: (v) => v == null ? 'Choose a category' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _brands.any((b) => b.id == _brandId) ? _brandId : null,
                        decoration: const InputDecoration(labelText: 'Brand'),
                        items: [for (final b in _brands) DropdownMenuItem(value: b.id, child: Text(b.isActive ? b.name : '${b.name} (inactive)'))],
                        onChanged: (v) => _brandId = v,
                        validator: (v) => v == null ? 'Choose a brand' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _basePrice,
                        decoration: const InputDecoration(labelText: 'Base price (VND)', helperText: 'Shown until the product has active variants'),
                        keyboardType: TextInputType.number,
                        validator: Validators.money,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active (visible in shop)'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                      BusyButton(label: product == null ? 'Create product' : 'Save product', onPressed: _save),
                    ]),
                  ),
                  if (product != null) ...[
                    const SizedBox(height: 24),
                    _VariantsSection(product: product, onChanged: _reloadProduct),
                    const SizedBox(height: 24),
                    _ImagesSection(product: product, onChanged: _reloadProduct),
                  ],
                ]),
    );
  }
}

class _VariantsSection extends ConsumerWidget {
  const _VariantsSection({required this.product, required this.onChanged});

  final ProductDetail product;
  final Future<void> Function() onChanged;

  Future<void> _edit(BuildContext context, WidgetRef ref, Variant? variant) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _VariantDialog(productId: product.id, variant: variant));
    if (saved == true) await onChanged();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Variant v) async {
    if (!await confirmDialog(context, title: 'Delete variant', message: 'Delete ${v.label} (${v.sku})?', confirmLabel: 'Delete', destructive: true)) return;
    if (!context.mounted) return;
    await runGuarded(context, () async {
      final result = await ref.read(adminServiceProvider).deleteVariant(v.id);
      if (context.mounted) showMessage(context, result.message);
      await onChanged();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Variants (${product.variants.length})', style: Theme.of(context).textTheme.titleMedium)),
          TextButton.icon(onPressed: () => _edit(context, ref, null), icon: const Icon(Icons.add), label: const Text('Add variant')),
        ]),
        if (product.variants.isEmpty) const Text('Add at least one size/color variant so customers can buy this product.'),
        for (final v in product.variants)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              title: Text('${v.label} · ${formatVnd(v.price)}'),
              subtitle: Text('SKU ${v.sku} · stock ${v.stockQuantity}'),
              leading: StatusChip.active(v.isActive),
              trailing: PopupMenuButton<String>(
                onSelected: (a) => switch (a) {
                  'edit' => _edit(context, ref, v),
                  'stock' => context.push('/admin/inventory/movements?variantId=${v.id}&title=${Uri.encodeComponent(v.sku)}'),
                  _ => _delete(context, ref, v),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'stock', child: Text('Stock history')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
      ]);
}

class _VariantDialog extends ConsumerStatefulWidget {
  const _VariantDialog({required this.productId, this.variant});

  final int productId;
  final Variant? variant;

  @override
  ConsumerState<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends ConsumerState<_VariantDialog> {
  final _form = GlobalKey<FormState>();
  late final _sku = TextEditingController(text: widget.variant?.sku);
  late final _size = TextEditingController(text: widget.variant?.size);
  late final _color = TextEditingController(text: widget.variant?.color);
  late final _price = TextEditingController(text: widget.variant?.price.toStringAsFixed(0));
  final _stock = TextEditingController(text: '0');
  late bool _active = widget.variant?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_sku, _size, _color, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = {
      'sku': _sku.text.trim(),
      'size': _size.text.trim(),
      'color': _color.text.trim(),
      'price': parseMoney(_price.text),
      'isActive': _active,
      if (widget.variant == null) 'initialStock': int.tryParse(_stock.text) ?? 0,
    };
    final service = ref.read(adminServiceProvider);
    final ok = await runGuarded(
      context,
      () => widget.variant == null ? service.createVariant(widget.productId, data) : service.updateVariant(widget.variant!.id, data),
      success: 'Variant saved',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.variant == null ? 'New variant' : 'Edit variant'),
        content: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: _sku, decoration: const InputDecoration(labelText: 'SKU'), validator: (v) => Validators.required(v, 'SKU')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Color'), validator: (v) => Validators.required(v, 'Color'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _size, decoration: const InputDecoration(labelText: 'Size'), validator: (v) => Validators.required(v, 'Size'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Price (VND)'), keyboardType: TextInputType.number, validator: Validators.money),
              if (widget.variant == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(labelText: 'Initial stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Enter 0 or more' : null,
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Change stock from Inventory so every change is recorded.', style: TextStyle(fontSize: 12)),
                ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _active, onChanged: (v) => setState(() => _active = v)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          BusyButton(label: 'Save', onPressed: _save),
        ],
      );
}

class _ImagesSection extends ConsumerWidget {
  const _ImagesSection({required this.product, required this.onChanged});

  final ProductDetail product;
  final Future<void> Function() onChanged;

  static String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file == null || !context.mounted) return;
    await runGuarded(context, () async {
      final bytes = await file.readAsBytes();
      await ref.read(adminServiceProvider).uploadImage(product.id, bytes, file.name, file.mimeType ?? _contentType(file.name));
      await onChanged();
    }, success: 'Image uploaded');
  }

  Future<void> _addUrl(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add image URL'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'https://...'), keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty || !context.mounted) return;
    await runGuarded(context, () async {
      await ref.read(adminServiceProvider).addImageUrl(product.id, url);
      await onChanged();
    }, success: 'Image added');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(adminServiceProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('Images (${product.images.length})', style: Theme.of(context).textTheme.titleMedium)),
        IconButton(tooltip: 'Upload image', onPressed: () => _upload(context, ref), icon: const Icon(Icons.upload_outlined)),
        IconButton(tooltip: 'Add image URL', onPressed: () => _addUrl(context, ref), icon: const Icon(Icons.link)),
      ]),
      if (product.images.isEmpty) const Text('No images yet. JPEG, PNG or WebP, up to 5 MB.'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (index, image) in product.images.indexed)
          SizedBox(
            width: 120,
            child: Column(children: [
              Stack(children: [
                AppImage(image.url, width: 120, height: 120),
                if (image.isPrimary)
                  const Positioned(left: 4, top: 4, child: StatusChip('Primary', color: Colors.blue)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Move left',
                  onPressed: index == 0
                      ? null
                      : () => runGuarded(context, () async {
                            await service.updateImage(image.id, altText: image.altText, displayOrder: product.images[index - 1].displayOrder - 1, isPrimary: image.isPrimary);
                            await onChanged();
                          }),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Set as primary',
                  onPressed: image.isPrimary
                      ? null
                      : () => runGuarded(context, () async {
                            await service.updateImage(image.id, altText: image.altText, displayOrder: image.displayOrder, isPrimary: true);
                            await onChanged();
                          }),
                  icon: Icon(image.isPrimary ? Icons.star : Icons.star_border),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete image',
                  onPressed: () async {
                    if (!await confirmDialog(context, title: 'Delete image', message: 'Remove this image from the product?', confirmLabel: 'Delete', destructive: true)) return;
                    if (!context.mounted) return;
                    await runGuarded(context, () async {
                      await service.deleteImage(image.id);
                      await onChanged();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ]),
            ]),
          ),
      ]),
    ]);
  }
}
