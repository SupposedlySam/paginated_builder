import 'package:example/l10n/l10n.dart';
import 'package:example/paginated_builder/cubit/basic_paginated_builder_cubit.dart';
import 'package:example/paginated_builder/view/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paginated_builder/paginated_builder.dart';

class BasicPaginatedBuilderPage extends StatelessWidget {
  const BasicPaginatedBuilderPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BasicPaginatedBuilderCubit(),
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

class BasicPaginatedBuilderView extends StatelessWidget {
  const BasicPaginatedBuilderView({
    required this.allPosts,
    super.key,
  });
  final List<Post> allPosts;

  Widget itemBuilder(
    BuildContext context,
    ItemComparator<Post> comparator, [
    Animation<double>? animation,
  ]) {
    Widget toColumn(Post post, String position) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        key: Key('${post.id}_$position'),
        children: [Text(post.title)],
      );
    }

    return Row(
      children: [
        toColumn(comparator.previous, 'previous'),
        toColumn(comparator.current, 'current'),
        toColumn(comparator.next, 'next'),
      ],
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
        ? allPosts.take(limit)
        : allPosts
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
      body: PaginatedComparator<Post, Post>(
        chunkDataLimit: 10,
        dataChunker: handleGetNext,
        itemBuilder: itemBuilder,
        listBuilder: listBuilder,
        refreshListWhenSourceChanges: true,
      ),
    );
  }
}
