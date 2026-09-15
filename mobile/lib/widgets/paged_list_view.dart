import 'package:flutter/material.dart';

import '../models/common.dart';
import 'state_views.dart';

/// Infinite-scrolling list over a paged API endpoint with loading, empty, error and
/// pull-to-refresh states. Change [queryKey] to restart from page 1 with new criteria.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.queryKey,
    this.emptyMessage = 'Nothing here yet.',
    this.emptyIcon = Icons.inbox_outlined,
    this.padding = const EdgeInsets.all(12),
    this.separator = const SizedBox(height: 8),
    this.header,
    this.gridDelegate,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item, VoidCallback reload) itemBuilder;
  final Object? queryKey;
  final String emptyMessage;
  final IconData emptyIcon;
  final EdgeInsets padding;
  final Widget separator;
  final Widget? header;

  /// When set, items are laid out in a grid instead of a list.
  final SliverGridDelegate? gridDelegate;

  @override
  State<PagedListView<T>> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final _items = <T>[];
  final _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Reloads from the first page, e.g. after an item was edited.
  Future<void> reload() => _load(reset: true);

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || !_hasMore || _error != null)) return;
    final generation = reset ? ++_generation : _generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _hasMore = true;
      }
    });
    try {
      final result = await widget.fetch(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_loading) return Column(children: [if (widget.header != null) widget.header!, const Expanded(child: LoadingView())]);
      if (_error != null) {
        return Column(children: [
          if (widget.header != null) widget.header!,
          Expanded(child: ErrorView(error: _error!, onRetry: reload)),
        ]);
      }
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(children: [
          if (widget.header != null) widget.header!,
          SizedBox(height: 360, child: EmptyView(message: widget.emptyMessage, icon: widget.emptyIcon)),
        ]),
      );
    }

    final footer = _error != null
        ? Padding(padding: const EdgeInsets.all(8), child: Center(child: TextButton(onPressed: () => setState(() => _error = null), child: const Text('Load more'))))
        : _hasMore
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            : const SizedBox(height: 16);

    return RefreshIndicator(
      onRefresh: reload,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: widget.padding,
            sliver: widget.gridDelegate != null
                ? SliverGrid(
                    gridDelegate: widget.gridDelegate!,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => widget.itemBuilder(context, _items[i], reload),
                      childCount: _items.length,
                    ),
                  )
                : SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => widget.separator,
                    itemBuilder: (context, i) => widget.itemBuilder(context, _items[i], reload),
                  ),
          ),
          SliverToBoxAdapter(child: footer),
        ],
      ),
    );
  }
}
