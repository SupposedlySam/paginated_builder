import 'package:example/l10n/l10n.dart';
import 'package:example/paginated_builder/cubit/basic_paginated_builder_cubit.dart';
import 'package:example/paginated_builder/view/post_model.dart';
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
  int itemCacheLength = 0;

  final GlobalKey<PaginatedComparatorState<Post, Post>> paginatorKey =
      GlobalKey<PaginatedComparatorState<Post, Post>>();

  int getChunksRequested() => paginatorKey.currentState?.chunksRequested ?? 0;

  int getItemCacheLength() => paginatorKey.currentState?.cacheLength ?? 0;

  Widget itemBuilder(
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
                toColumn(comparator.previous, 'previous'),
                toColumn(comparator.current, 'current'),
                toColumn(comparator.next, 'next'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget listBuilder(
    int? initialItemCount,
    NullableIndexedWidgetBuilder paginatedItemBuilder,
  ) {
    return ListView.builder(
      itemCount: initialItemCount,
      itemBuilder: paginatedItemBuilder,
    );
  }

  Future<List<Post>> handleGetNext(Post? cursor, int limit) async {
    final isFirstRun = cursor == null;

    final data = isFirstRun
        ? widget.allPosts.take(limit)
        : widget.allPosts
            .skipWhile((post) => post != cursor)
            .skip(1) // Start after the previous cursor
            .take(limit);

    return data.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.basicPaginatedBuilderAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Chunk Size: ${BasicPaginatedBuilderPage.chunkSize}'),
                Text(
                  'Total Comparators: ${BasicPaginatedBuilderPage.itemCount}',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chunks Requested: $chunkCount'),
                Text('Cached Item Length: $itemCacheLength'),
              ],
            ),
            const Divider(),
            Expanded(
              child: PaginatedComparator<Post, Post>(
                key: paginatorKey,
                chunkDataLimit: BasicPaginatedBuilderPage.chunkSize,
                dataChunker: handleGetNext,
                itemBuilder: itemBuilder,
                listBuilder: listBuilder,
                // Required when using a List wiget that doesn't allow
                // item insertion
                rebuildListWhenChunkIsCached: true,
                onListRebuild: () {
                  final chunksRequested = getChunksRequested();
                  final itemCacheLength = getItemCacheLength();
                  setState(
                    () {
                      chunkCount = chunksRequested;
                      this.itemCacheLength = itemCacheLength;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
