import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/shopping_providers.dart';
import '../../services/shopping_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

/// Delivery address book (UC-009 – UC-012). In select mode a tap returns the address to checkout.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key, this.selectMode = false});

  final bool selectMode;

  Future<void> _delete(BuildContext context, WidgetRef ref, Address a) async {
    if (!await confirmDialog(context, title: 'Delete address', message: 'Delete the address of ${a.recipientName}?', confirmLabel: 'Delete', destructive: true)) return;
    if (!context.mounted) return;
    final ok = await runGuarded(context, () => ref.read(addressServiceProvider).delete(a.id), success: 'Address deleted');
    if (ok) ref.invalidate(addressesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(selectMode ? 'Choose address' : 'Delivery addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/addresses/new');
          ref.invalidate(addressesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: AsyncValueView(
        value: addresses,
        onRetry: () => ref.invalidate(addressesProvider),
        data: (list) => list.isEmpty
            ? const EmptyView(message: 'No saved addresses yet.', icon: Icons.location_off_outlined)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = list[i];
                  return Card(
                    child: ListTile(
                      onTap: selectMode ? () => context.pop(a) : null,
                      leading: Icon(a.isDefault ? Icons.home : Icons.location_on_outlined),
                      title: Row(children: [
                        Flexible(child: Text(a.recipientName)),
                        if (a.isDefault) ...[const SizedBox(width: 8), const StatusChip('Default', color: Colors.blue)],
                      ]),
                      subtitle: Text('${a.phoneNumber}\n${a.fullAddress}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await context.push('/addresses/${a.id}/edit');
                            ref.invalidate(addressesProvider);
                          } else {
                            await _delete(context, ref, a);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final int? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line = TextEditingController();
  final _ward = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  bool _isDefault = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.addressId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(addressServiceProvider).list();
      final a = list.firstWhere((x) => x.id == widget.addressId);
      _name.text = a.recipientName;
      _phone.text = a.phoneNumber;
      _line.text = a.addressLine;
      _ward.text = a.ward;
      _district.text = a.district;
      _city.text = a.city;
      _isDefault = a.isDefault;
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line, _ward, _district, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = {
      'recipientName': _name.text.trim(),
      'phoneNumber': _phone.text.trim(),
      'addressLine': _line.text.trim(),
      'ward': _ward.text.trim(),
      'district': _district.text.trim(),
      'city': _city.text.trim(),
      'isDefault': _isDefault,
    };
    final service = ref.read(addressServiceProvider);
    final ok = await runGuarded(
      context,
      () => widget.addressId == null ? service.create(data) : service.update(widget.addressId!, data),
      success: 'Address saved',
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label, {TextInputType? type, String? Function(String?)? validator}) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: c,
            keyboardType: type,
            decoration: InputDecoration(labelText: label),
            validator: validator ?? (v) => Validators.required(v, label),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(widget.addressId == null ? 'New address' : 'Edit address')),
      body: !_loaded
          ? const LoadingView()
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                field(_name, 'Recipient name'),
                field(_phone, 'Phone number', type: TextInputType.phone, validator: (v) => Validators.phone(v, required: true)),
                field(_line, 'Street address'),
                field(_ward, 'Ward'),
                field(_district, 'District'),
                field(_city, 'City / Province'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use as default address'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 16),
                BusyButton(label: 'Save address', onPressed: _save),
              ]),
            ),
    );
  }
}
