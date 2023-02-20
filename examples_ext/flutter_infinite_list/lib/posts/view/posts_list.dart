import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_infinite_list/posts/posts.dart';
import 'package:paginated_builder/paginated_builder.dart';

class PostsList extends StatelessWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostBloc>();

    return PaginatedBuilder<Post, int>(
      chunkDataLimit: 10,
      emptyWidget: const Center(child: Text('no posts')),
      thresholdPercent: 0.9,
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
      dataChunker: (int? cursor, int limit) {
        return bloc.fetchPosts(cursor ?? 0, limit);
      },
    );
  }
}
