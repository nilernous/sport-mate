import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../models/catalog.dart';
import '../../models/common.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Categories (UC-018 – UC-021) and brands (UC-022 – UC-025).
class CatalogSetupScreen extends StatelessWidget {
  const CatalogSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Categories & brands'),
            bottom: const TabBar(tabs: [Tab(text: 'Categories'), Tab(text: 'Brands')]),
          ),
          body: const TabBarView(children: [_CatalogList(isBrand: false), _CatalogList(isBrand: true)]),
        ),
      );
}

/// Name/description/active entry shared by categories and brands.
class _Entry {
  const _Entry(this.id, this.name, this.description, this.isActive, this.productCount, {this.logoUrl});

  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int productCount;
  final String? logoUrl;
}

class _CatalogList extends ConsumerStatefulWidget {
  const _CatalogList({required this.isBrand});

  final bool isBrand;

  @override
  ConsumerState<_CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends ConsumerState<_CatalogList> with AutomaticKeepAliveClientMixin {
  late Future<List<_Entry>> _future = _load();

  @override
  bool get wantKeepAlive => true;

  String get _noun => widget.isBrand ? 'brand' : 'category';

  Future<List<_Entry>> _load() async {
    final service = ref.read(adminServiceProvider);
    if (widget.isBrand) {
      return (await service.brands()).map((Brand b) => _Entry(b.id, b.name, b.description, b.isActive, b.productCount, logoUrl: b.logoUrl)).toList();
    }
    return (await service.categories()).map((Category c) => _Entry(c.id, c.name, c.description, c.isActive, c.productCount)).toList();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _edit(_Entry? entry) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _EntryDialog(isBrand: widget.isBrand, entry: entry));
    if (saved == true) _reload();
  }

  Future<void> _delete(_Entry entry) async {
    if (!await confirmDialog(context,
        title: 'Delete $_noun',
        message: '${entry.name} is deactivated instead of deleted if products use it.',
        confirmLabel: 'Delete',
        destructive: true)) {
      return;
    }
    if (!mounted) return;
    await runGuarded(context, () async {
      final service = ref.read(adminServiceProvider);
      final DeleteResult result = widget.isBrand ? await service.deleteBrand(entry.id) : await service.deleteCategory(entry.id);
      if (mounted) showMessage(context, result.message);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _noun,
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: Text('New $_noun'),
      ),
      body: FutureBuilder<List<_Entry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _reload);
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) return EmptyView(message: 'No ${_noun}s yet.');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = list[i];
              return Card(
                child: ListTile(
                  title: Text(e.name),
                  subtitle: Text('${e.productCount} products${(e.description ?? '').isEmpty ? '' : ' · ${e.description}'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  leading: StatusChip.active(e.isActive),
                  trailing: PopupMenuButton<String>(
                    onSelected: (a) => a == 'edit' ? _edit(e) : _delete(e),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => _edit(e),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EntryDialog extends ConsumerStatefulWidget {
  const _EntryDialog({required this.isBrand, this.entry});

  final bool isBrand;
  final _Entry? entry;

  @override
  ConsumerState<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends ConsumerState<_EntryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.entry?.name);
  late final _description = TextEditingController(text: widget.entry?.description);
  late final _logo = TextEditingController(text: widget.entry?.logoUrl);
  late bool _active = widget.entry?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final service = ref.read(adminServiceProvider);
    final data = {
      'name': _name.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'isActive': _active,
      if (widget.isBrand) 'logoUrl': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
    };
    final ok = await runGuarded(context, () => widget.isBrand ? service.saveBrand(widget.entry?.id, data) : service.saveCategory(widget.entry?.id, data),
        success: 'Saved');
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final noun = widget.isBrand ? 'brand' : 'category';
    return AlertDialog(
      title: Text(widget.entry == null ? 'New $noun' : 'Edit $noun'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => Validators.required(v, 'Name')),
            const SizedBox(height: 12),
            TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            if (widget.isBrand) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _logo, decoration: const InputDecoration(labelText: 'Logo URL (optional)'), keyboardType: TextInputType.url),
            ],
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
}
