import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/admin.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/state_views.dart';

class _ReportData {
  const _ReportData(this.summary, this.topProducts, this.statusReport);

  final DashboardSummary summary;
  final List<TopProduct> topProducts;
  final OrderReport statusReport;
}

/// Sales dashboard, order report and best sellers (UC-076 – UC-078). Admin only.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _ranges = {7: '7 days', 30: '30 days', 90: '90 days'};
  int _days = 30;
  late Future<_ReportData> _future = _load();

  Future<_ReportData> _load() async {
    final service = ref.read(adminServiceProvider);
    final to = DateTime.now();
    final from = to.subtract(Duration(days: _days - 1));
    final results = await Future.wait([
      service.dashboard(from: from, to: to),
      service.topProducts(from: from, to: to, limit: 5),
      service.orderReport(from: from, to: to, groupBy: 'status'),
    ]);
    return _ReportData(results[0] as DashboardSummary, results[1] as List<TopProduct>, results[2] as OrderReport);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Column(children: [
          // Filters sit in one row above the content.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<int>(
              segments: [for (final e in _ranges.entries) ButtonSegment(value: e.key, label: Text(e.value))],
              selected: {_days},
              onSelectionChanged: (s) {
                _days = s.first;
                _reload();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<_ReportData>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _reload);
                if (!snap.hasData) return const LoadingView();
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: _DashboardBody(snap.data!),
                );
              },
            ),
          ),
        ]),
      );
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody(this.data);

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    final s = data.summary;
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${formatDate(s.from)} – ${formatDate(s.to)}', style: theme.textTheme.labelLarge),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth > 700 ? (c.maxWidth - 36) / 4 : (c.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final tile in [
            ('Revenue', formatVnd(s.revenue), '${s.paidOrders} paid orders'),
            ('Orders', '${s.totalOrders}', '${s.cancelledOrders} cancelled'),
            ('Avg. order value', formatVnd(s.averageOrderValue), 'paid orders'),
            ('New customers', '${s.newCustomers}', '${s.lowStockVariants} low-stock items'),
          ])
            SizedBox(width: width, child: _StatTile(label: tile.$1, value: tile.$2, caption: tile.$3)),
        ]);
      }),
      const SizedBox(height: 20),
      Text('Daily revenue', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Tap a bar for details.', style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      SizedBox(height: 180, child: _RevenueBars(s.dailyRevenue)),
      const SizedBox(height: 20),
      Text('Orders by status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _StatusTable(data.statusReport),
      const SizedBox(height: 20),
      Text('Best-selling products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (data.topProducts.isEmpty)
        const Text('No paid orders in this period yet.')
      else
        Card(
          child: Column(children: [
            for (final p in data.topProducts)
              ListTile(
                leading: CircleAvatar(child: Text('${p.rank}')),
                title: Text(p.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${p.quantitySold} sold'),
                trailing: Text(formatVnd(p.revenue), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      const SizedBox(height: 16),
      Text(s.revenueDefinition, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.caption});

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(caption, style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}

/// Single-series bar chart: one hue, thin bars with rounded data ends, a 2px gap,
/// a recessive baseline, and a per-bar tooltip.
class _RevenueBars extends StatelessWidget {
  const _RevenueBars(this.days);

  final List<DailyRevenue> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = days.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);
    if (max == 0) return const Center(child: Text('No paid revenue in this period.'));

    return Column(children: [
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final d in days)
            Expanded(
              child: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                message: '${formatDate(d.date)}\n${formatVnd(d.revenue)} · ${d.orders} orders placed',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: d.revenue == 0 ? 0 : (d.revenue / max * 150).clamp(3, 150),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
      Divider(height: 1, color: theme.colorScheme.outlineVariant),
      const SizedBox(height: 4),
      Row(children: [
        Text(formatDate(days.first.date), style: theme.textTheme.labelSmall),
        const Spacer(),
        Text('Peak ${formatVnd(max)}', style: theme.textTheme.labelSmall),
        const Spacer(),
        Text(formatDate(days.last.date), style: theme.textTheme.labelSmall),
      ]),
    ]);
  }
}

/// Order report grouped by status, as a table with magnitude bars.
class _StatusTable extends StatelessWidget {
  const _StatusTable(this.report);

  final OrderReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = report.rows.fold<int>(0, (m, r) => r.orderCount > m ? r.orderCount : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          for (final row in report.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 90, child: Text(parseOrderStatus(row.group).label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : row.orderCount / max,
                      minHeight: 10,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(width: 36, child: Text('${row.orderCount}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 120, child: Text(formatVnd(row.totalAmount), textAlign: TextAlign.end, style: theme.textTheme.bodySmall)),
              ]),
            ),
          const Divider(),
          InfoRow('Total', '${report.totalOrders} orders · ${formatVnd(report.totalAmount)}', bold: true),
        ]),
      ),
    );
  }
}
