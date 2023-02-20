import 'package:example/l10n/l10n.dart';
import 'package:example/paginated_builder/cubit/basic_paginated_builder_cubit.dart';
import 'package:example/paginated_builder/models/metrics_copy.dart';
import 'package:example/paginated_builder/models/post.dart';
import 'package:example/paginated_builder/view/widgets/builder_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paginated_builder/paginated_builder.dart';

class BasicPaginatedBuilderPage extends StatelessWidget {
  const BasicPaginatedBuilderPage({super.key});

  static const int itemCount = 50;
  static const chunkSize = 10;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BasicPaginatedBuilderCubit(itemCount)..generateItems(),
      child: Builder(
        builder: (context) => BasicPaginatedBuilderView(
          allPosts: context.select(
            (BasicPaginatedBuilderCubit cubit) => cubit.state,
          ),
        ),
      ),
    );
  }
}

class BasicPaginatedBuilderView extends StatefulWidget {
  const BasicPaginatedBuilderView({
    required this.allPosts,
    super.key,
  });

  final List<Post> allPosts;

  @override
  State<BasicPaginatedBuilderView> createState() =>
      _BasicPaginatedBuilderViewState();
}

class _BasicPaginatedBuilderViewState extends State<BasicPaginatedBuilderView> {
  int chunkCount = 0;
  int cacheCount = 0;

  final GlobalKey<PaginatedComparatorState<Post, Post>> paginatorKey =
      GlobalKey<PaginatedComparatorState<Post, Post>>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.basicPaginatedBuilderAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            BuilderMetrics(
              chunkCount: chunkCount,
              itemCacheLength: cacheCount,
              copy: MetricsCopy.localized(l10n),
            ),
            const Divider(),
            Expanded(
              child: PaginatedComparator<Post, Post>(
                key: paginatorKey,
                chunkDataLimit: BasicPaginatedBuilderPage.chunkSize,
                dataChunker: _handleGetNext,
                itemBuilder: _itemBuilder,
                listBuilder: _listBuilder,
                // Required when using a List wiget that doesn't allow
                // item insertion
                rebuildListWhenChunkIsCached: true,
                onListRebuild: _updateBuilderMetrics,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates each item shown in the list
  ///
  /// Called for each item in the list. This will most likely be called multiple
  /// times for each item because the list we're using in the [_listBuilder]
  /// will remove items as they're scrolled off the screen and recreate them as
  /// they are scrolled back into view.
  Widget _itemBuilder(
    BuildContext context,
    ItemComparator<Post> comparator, [
    Animation<double>? animation,
  ]) {
    Widget toColumn(Post post, String position) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        key: Key('${post.id}_$position'),
        children: [
          Text(
            position,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge,
          )
        ],
      );
    }

    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Comparator ${comparator.currentItem.index + 1}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                toColumn(comparator.previous, l10n.previousLabel),
                toColumn(comparator.current, l10n.currentLabel),
                toColumn(comparator.next, l10n.nextLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Controls what Widget is used to display the items being paginated through
  Widget _listBuilder(
    int? initialItemCount,
    NullableIndexedWidgetBuilder paginatedItemBuilder,
  ) {
    return ListView.builder(
      itemCount: initialItemCount,
      itemBuilder: paginatedItemBuilder,
    );
  }

  /// Manual paginator when you already have the full list of items
  ///
  /// Accepts a cursor (the last item in the previous chunk) and a
  /// limit (how many items should be returned at a time)
  Future<List<Post>> _handleGetNext(Post? cursor, int limit) async {
    // If the cursor is null it means there was no previous chunk
    final isFirstRun = cursor == null;

    final data = isFirstRun
        // starting at the beginning of the list, get the maximum # of items
        ? widget.allPosts.take(limit)
        // otherwise, skip the ones we've already returned and get # of items
        : widget.allPosts
            .skipWhile((post) => post != cursor)
            .skip(1) // Start after the previous cursor
            .take(limit);

    // Adds artificial network delay to show item loading widget
    return Future.delayed(const Duration(seconds: 1), data.toList);
  }

  /// Triggers an update to the view with the latest values from the paginated
  /// builder
  void _updateBuilderMetrics() {
    final chunksRequested = paginatorKey.currentState?.chunksRequested ?? 0;
    final itemCacheLength = paginatorKey.currentState?.cacheLength ?? 0;

    setState(
      () {
        chunkCount = chunksRequested;
        cacheCount = itemCacheLength;
      },
    );
  }
}
