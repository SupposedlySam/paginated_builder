import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_infinite_list/posts/posts.dart';
import 'package:flutter_infinite_list/posts/view/posts_list/widgets/widgets.dart';
import 'package:paginated_builder/paginated_builder.dart';

class PostsList extends StatelessWidget {
  const PostsList({
    required this.onListRebuild,
    required this.paginatorKey,
    super.key,
  });

  final VoidCallback onListRebuild;
  final GlobalKey<PaginatedBuilderState<Post, int>> paginatorKey;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostBloc>();

    return PaginatedBuilder<Post, int>(
      key: paginatorKey,
      chunkDataLimit: PostsPage.chunkSize,
      rebuildListWhenChunkIsCached: true,
      cursorSelector: (Post post) => post.id,
      listBuilder: (initialItemCount, paginatedItemBuilder) {
        return ListView.builder(
          itemBuilder: paginatedItemBuilder,
          itemCount: initialItemCount,
        );
      },
      itemBuilder: (context, data, [animation]) {
        return PostListItem(post: data.item);
      },
      dataChunker: bloc.fetchPosts,
      onListRebuild: onListRebuild,
      emptyWidget: const EmptyView(),
      pageLoadingWidget: ShimmerView(),
      itemLoadingWidget: ShimmerItem(),
    );
  }
}
