import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../models/admin.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

/// Stock per variant and manual adjustments (UC-043, UC-044).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _keyword;
  bool _lowStockOnly = false;
  int _version = 0;

  Future<void> _adjust(InventoryItem item) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _AdjustDialog(item: item));
    if (saved == true) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: [
            IconButton(tooltip: 'Movement history', icon: const Icon(Icons.history), onPressed: () => context.push('/admin/inventory/movements')),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search product or SKU', prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) => setState(() => _keyword = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              FilterChip(label: const Text('Low stock (≤ 5)'), selected: _lowStockOnly, onSelected: (v) => setState(() => _lowStockOnly = v)),
            ]),
          ),
          Expanded(
            child: PagedListView<InventoryItem>(
              queryKey: (_keyword, _lowStockOnly, _version),
              fetch: (page) => ref.read(adminServiceProvider).inventory(keyword: _keyword, maxStock: _lowStockOnly ? 5 : null, page: page),
              emptyMessage: 'No variants found.',
              itemBuilder: (context, item, _) {
                final low = item.stockQuantity <= 5;
                return Card(
                  child: ListTile(
                    title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item.color} / ${item.size} · ${item.sku}${item.isActive ? '' : ' · inactive'}'),
                    leading: CircleAvatar(
                      backgroundColor: low ? Colors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${item.stockQuantity}', style: TextStyle(fontWeight: FontWeight.w700, color: low ? Colors.orange.shade900 : null)),
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: 'History',
                        icon: const Icon(Icons.history),
                        onPressed: () => context.push('/admin/inventory/movements?variantId=${item.variantId}&title=${Uri.encodeComponent(item.sku)}'),
                      ),
                      IconButton(tooltip: 'Adjust stock', icon: const Icon(Icons.edit_outlined), onPressed: () => _adjust(item)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
}

class _AdjustDialog extends ConsumerStatefulWidget {
  const _AdjustDialog({required this.item});

  final InventoryItem item;

  @override
  ConsumerState<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends ConsumerState<_AdjustDialog> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  bool _add = true;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final amount = int.parse(_quantity.text);
    final ok = await runGuarded(
      context,
      () => ref.read(adminServiceProvider).adjustStock(widget.item.variantId, _add ? amount : -amount, _reason.text.trim()),
      success: 'Stock updated',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Adjust ${widget.item.sku}'),
        content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Current stock: ${widget.item.stockQuantity}'),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: true, label: Text('Add')), ButtonSegment(value: false, label: Text('Remove'))],
              selected: {_add},
              onSelectionChanged: (s) => setState(() => _add = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a whole number greater than 0';
                if (!_add && n > widget.item.stockQuantity) return 'Stock cannot go below 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason', hintText: 'e.g. Restock, damaged, stock count'),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Give a short reason' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          BusyButton(label: 'Save', onPressed: _save),
        ],
      );
}

/// Inventory movement history (UC-045).
class StockMovementsScreen extends ConsumerWidget {
  const StockMovementsScreen({super.key, this.variantId, this.title});

  final int? variantId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(title == null ? 'Stock movements' : 'History · $title')),
        body: PagedListView<StockMovement>(
          fetch: (page) => ref.read(adminServiceProvider).movements(variantId: variantId, page: page),
          emptyMessage: 'No stock movements recorded.',
          separator: const Divider(height: 1),
          padding: EdgeInsets.zero,
          itemBuilder: (context, m, _) {
            final positive = m.quantityChange > 0;
            return ListTile(
              leading: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward, color: positive ? Colors.green : Colors.red),
              title: Text('${positive ? '+' : ''}${m.quantityChange} → ${m.quantityAfter} · ${humanize(m.type)}'),
              subtitle: Text([
                '${m.productName} (${m.sku})',
                formatDateTime(m.createdAt),
                if (m.actorName != null) m.actorName!,
                if ((m.reason ?? '').isNotEmpty) m.reason!,
              ].join(' · ')),
            );
          },
        ),
      );
}
