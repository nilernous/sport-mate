import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/admin.dart';
import '../../models/catalog.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

final _couponsProvider = FutureProvider.autoDispose<List<Coupon>>((ref) async => (await ref.watch(adminServiceProvider).coupons()).items);

/// Coupon list (UC-062). Admin only.
class CouponListScreen extends ConsumerWidget {
  const CouponListScreen({super.key});

  String _discount(Coupon c) => c.isPercentage
      ? '${c.discountValue.toStringAsFixed(0)}% off${c.maxDiscountAmount == null ? '' : ' (max ${formatVnd(c.maxDiscountAmount!)})'}'
      : '${formatVnd(c.discountValue)} off';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(_couponsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/coupons/new');
          ref.invalidate(_couponsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('New coupon'),
      ),
      body: AsyncValueView(
        value: coupons,
        onRetry: () => ref.invalidate(_couponsProvider),
        data: (list) => list.isEmpty
            ? const EmptyView(message: 'No coupons yet.', icon: Icons.local_offer_outlined)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(_couponsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return Card(
                      child: ListTile(
                        title: Row(children: [
                          Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(width: 8),
                          c.isExpired ? const StatusChip('Expired', color: Colors.grey) : StatusChip.active(c.isActive),
                        ]),
                        subtitle: Text([
                          _discount(c),
                          if (c.minOrderAmount > 0) 'min ${formatVnd(c.minOrderAmount)}',
                          if (c.applicableCategoryName != null) c.applicableCategoryName!,
                          'used ${c.usedCount}${c.usageLimit == null ? '' : '/${c.usageLimit}'}',
                          '${formatDate(c.startsAt)} – ${formatDate(c.endsAt)}',
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await context.push('/admin/coupons/${c.id}');
                          ref.invalidate(_couponsProvider);
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// Create/update/delete a coupon (UC-061, UC-063, UC-064).
class CouponFormScreen extends ConsumerStatefulWidget {
  const CouponFormScreen({super.key, this.couponId});

  final int? couponId;

  @override
  ConsumerState<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends ConsumerState<CouponFormScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _value = TextEditingController();
  final _maxDiscount = TextEditingController();
  final _minOrder = TextEditingController(text: '0');
  final _usageLimit = TextEditingController();
  final _perUser = TextEditingController();
  bool _percentage = true;
  bool _active = true;
  int? _categoryId;
  DateTimeRange _period = DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 30)));
  List<Category> _categories = const [];
  int _usedCount = 0;
  bool _loading = true;
  Object? _error;

  AdminService get _service => ref.read(adminServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_code, _description, _value, _maxDiscount, _minOrder, _usageLimit, _perUser]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _categories = await _service.categories();
      if (widget.couponId != null) {
        final c = await _service.coupon(widget.couponId!);
        _code.text = c.code;
        _description.text = c.description ?? '';
        _percentage = c.isPercentage;
        _value.text = c.discountValue.toStringAsFixed(0);
        _maxDiscount.text = c.maxDiscountAmount?.toStringAsFixed(0) ?? '';
        _minOrder.text = c.minOrderAmount.toStringAsFixed(0);
        _usageLimit.text = c.usageLimit?.toString() ?? '';
        _perUser.text = c.perUserLimit?.toString() ?? '';
        _categoryId = c.applicableCategoryId;
        _active = c.isActive;
        _period = DateTimeRange(start: c.startsAt.toLocal(), end: c.endsAt.toLocal());
        _usedCount = c.usedCount;
      }
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _period,
    );
    if (picked != null) setState(() => _period = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    int? optionalInt(TextEditingController c) => c.text.trim().isEmpty ? null : int.parse(c.text.trim());
    final start = DateTime(_period.start.year, _period.start.month, _period.start.day);
    final end = DateTime(_period.end.year, _period.end.month, _period.end.day, 23, 59, 59);
    final data = {
      'code': _code.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'discountType': _percentage ? 'Percentage' : 'FixedAmount',
      'discountValue': parseMoney(_value.text),
      'maxDiscountAmount': _percentage && _maxDiscount.text.trim().isNotEmpty ? parseMoney(_maxDiscount.text) : null,
      'minOrderAmount': parseMoney(_minOrder.text) ?? 0,
      'applicableCategoryId': _categoryId,
      'startsAt': start.toUtc().toIso8601String(),
      'endsAt': end.toUtc().toIso8601String(),
      'usageLimit': optionalInt(_usageLimit),
      'perUserLimit': optionalInt(_perUser),
      'isActive': _active,
    };
    final ok = await runGuarded(context, () => _service.saveCoupon(widget.couponId, data), success: 'Coupon saved');
    if (ok && mounted) context.pop();
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context,
        title: 'Delete coupon',
        message: 'Coupons that were already used are deactivated instead of deleted.',
        confirmLabel: 'Delete',
        destructive: true)) {
      return;
    }
    if (!mounted) return;
    await runGuarded(context, () async {
      final result = await _service.deleteCoupon(widget.couponId!);
      if (!mounted) return;
      showMessage(context, result.message);
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    String? optionalPositive(String? v) => (v ?? '').trim().isEmpty ? null : Validators.positiveInt(v);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.couponId == null ? 'New coupon' : 'Edit coupon'),
        actions: [if (widget.couponId != null) IconButton(tooltip: 'Delete coupon', onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(error: _error!)
              : Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    if (_usedCount > 0)
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Used $_usedCount times. Changes do not affect existing orders.')),
                    TextFormField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Code', helperText: 'Letters, digits, - and _'),
                      validator: (v) => RegExp(r'^[A-Za-z0-9_-]{3,50}$').hasMatch((v ?? '').trim()) ? null : '3–50 letters, digits, - or _',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [ButtonSegment(value: true, label: Text('Percentage')), ButtonSegment(value: false, label: Text('Fixed amount'))],
                      selected: {_percentage},
                      onSelectionChanged: (s) => setState(() => _percentage = s.first),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: _percentage ? 'Discount (%)' : 'Discount (VND)'),
                          validator: (v) {
                            final base = Validators.money(v, allowZero: false);
                            if (base != null) return base;
                            return _percentage && parseMoney(v!)! > 100 ? 'At most 100%' : null;
                          },
                        ),
                      ),
                      if (_percentage) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxDiscount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Max discount (VND)'),
                            validator: (v) => (v ?? '').trim().isEmpty ? null : Validators.money(v, allowZero: false),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(controller: _minOrder, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum order (VND)'), validator: Validators.money),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Applies to'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All products')),
                        for (final c in _categories) DropdownMenuItem(value: c.id, child: Text('Only ${c.name}')),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.date_range),
                      title: const Text('Valid period'),
                      subtitle: Text('${formatDate(_period.start)} – ${formatDate(_period.end)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickPeriod,
                    ),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _usageLimit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total uses (optional)'),
                          validator: optionalPositive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _perUser,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Uses per customer'),
                          validator: optionalPositive,
                        ),
                      ),
                    ]),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _active, onChanged: (v) => setState(() => _active = v)),
                    const SizedBox(height: 8),
                    BusyButton(label: 'Save coupon', onPressed: _save),
                  ]),
                ),
    );
  }
}
