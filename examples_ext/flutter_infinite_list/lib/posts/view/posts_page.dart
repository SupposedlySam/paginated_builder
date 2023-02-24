import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_infinite_list/posts/posts.dart';
import 'package:http/http.dart' as http;
import 'package:paginated_builder/paginated_builder.dart';

import 'builder_metrics.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  static const chunkSize = 10;

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  int chunkCount = 0;
  int cacheCount = 0;

  final GlobalKey<PaginatedBuilderState<Post, int>> paginatorKey =
      GlobalKey<PaginatedBuilderState<Post, int>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: BlocProvider(
        create: (_) => PostBloc(httpClient: http.Client()),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0).copyWith(bottom: 12),
              child: BuilderMetrics(
                chunkCount: chunkCount,
                itemCacheLength: cacheCount,
                copy: MetricsCopy(
                  cachedItemLengthLabel: 'Cached Item Length:',
                  chunkSizeLabel: 'Chunk Size:',
                  chunksRequestedLabel: 'Chunks Requested:',
                  totalComparatorsLabel: 'Item Count:',
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: PostsList(
                onListRebuild: _updateBuilderMetrics,
                paginatorKey: paginatorKey,
              ),
            ),
          ],
        ),
      ),
    );
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
