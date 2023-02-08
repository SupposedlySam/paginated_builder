import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base.dart';

import '../models/post.dart';

void main() {
  final key =
      GlobalKey<PaginatedBaseState<Post, Post, PaginatedBuilder<Post, Post>>>();
  late Widget widget;
  late List<Post> allPosts;
  int getRequestedChunkCount() => key.currentState!.chunksRequested;
  final afterPageLoadChange = StreamController<Post>.broadcast(
    sync: true,
  );

  Widget itemBuilder(
    BuildContext context,
    Post post, [
    Animation<double>? animation,
  ]) =>
      ListTile(
        dense: true,
        key: ValueKey(post),
        title: Text(post.title),
        subtitle: Text(post.body),
        leading: Text(post.id.toString()),
      );

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

  setUp(() {
    allPosts = List.generate(100, (index) {
      final location = index + 1;
      return Post(id: location, title: 'post $location', body: 'post body');
    });

    widget = MaterialApp(
      home: Scaffold(
        body: PaginatedBuilder<Post, Post>(
          key: key,
          chunkDataLimit: 1,
          dataChunker: handleGetNext,
          itemBuilder: itemBuilder,
          afterPageLoadChangeStream: afterPageLoadChange.stream,
          listBuilder: listBuilder,
          enablePrintStatements: false,
        ),
      ),
    );
  });

  testWidgets('should render empty widget', (tester) async {
    allPosts.clear();
    await tester.pumpWidget(widget);
    await tester.pump(); // Runs builder

    expect(
      find.byType(DefaultEmptyView),
      findsOneWidget,
    );
  });

  testWidgets('should render loading widget', (tester) async {
    await tester.pumpWidget(widget);

    expect(
      find.byType(DefaultLoadingView),
      findsOneWidget,
    );
  });

  testWidgets('should show item', (tester) async {
    await tester.pumpWidget(widget); // Shows loading widget
    await tester.pump(); // Runs builder

    expect(find.text(allPosts.first.title), findsOneWidget);
  });

  testWidgets('should show data when source changes', (tester) async {
    const changedPost = Post(id: 0, title: 'post 0', body: 'post body');
    await tester.pumpWidget(widget); // Shows loading widget
    afterPageLoadChange.sink.add(changedPost);
    await tester.pump(); // Runs builder

    expect(find.text(changedPost.title), findsOneWidget);
  });

  group('with data limit enough for one view', () {
    setUp(() {
      widget = MaterialApp(
        home: Scaffold(
          body: PaginatedBuilder<Post, Post>(
            key: key,
            chunkDataLimit: 15,
            itemBuilder: itemBuilder,
            dataChunker: handleGetNext,
            listBuilder: listBuilder,
            enablePrintStatements: false,
            thresholdPercent: 1,
          ),
        ),
      );
    });

    testWidgets('should show chunk of data on load', (tester) async {
      // resets the screen to its original size after the test end
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(getRequestedChunkCount(), 1);
    });

    testWidgets('should request new chunk', (tester) async {
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 100));

      await tester.fling(
        find.byType(PaginatedBuilder<Post, Post>),
        const Offset(0, -1000),
        1000,
      );
      await tester.pumpAndSettle();

      expect(getRequestedChunkCount(), 2);
    });
  });
}
