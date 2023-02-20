import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_builder/paginated_builder.dart';

import '../models/post.dart';

void main() {
  final key =
      GlobalKey<PaginatedBaseState<Post, Post, PaginatedBuilder<Post, Post>>>();
  final afterPageLoadChange = StreamController<Post>.broadcast(
    sync: true,
  );

  Widget itemBuilder(
    BuildContext context,
    ItemData<Post> data, [
    Animation<double>? animation,
  ]) =>
      ListTile(
        dense: true,
        key: ValueKey(data),
        title: Text(data.item.title),
        subtitle: Text(data.item.body),
        leading: Text(data.item.id.toString()),
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

  Future<List<Post>> handleGetNext(
    List<Post> allPosts,
    Post? cursor,
    int limit,
  ) async {
    final isFirstRun = cursor == null;

    final data = isFirstRun
        ? allPosts.take(limit)
        : allPosts
            .skipWhile((post) => post != cursor)
            .skip(1) // Start after the previous cursor
            .take(limit);

    return data.toList();
  }

  group('happy path', () {
    late Widget widget;
    late List<Post> allPosts;
    int getRequestedChunkCount() => key.currentState!.chunksRequested;

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
            dataChunker: (cursor, limit) =>
                handleGetNext(allPosts, cursor, limit),
            itemBuilder: itemBuilder,
            rebuildListWhenChunkIsCached: true,
            enablePrintStatements: false,
            afterPageLoadChangeStream: afterPageLoadChange.stream,
            listBuilder: listBuilder,
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
        find.byType(DefaultPageLoadingView),
        findsOneWidget,
      );
    });

    testWidgets('should show item', (tester) async {
      await tester.pumpWidget(widget); // Shows loading widget
      await tester.pump(); // Loads first chunk with end loader
      await tester.pump(); // Loads next chunk (first item and end loader)

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
              dataChunker: (cursor, limit) =>
                  handleGetNext(allPosts, cursor, limit),
              listBuilder: listBuilder,
              rebuildListWhenChunkIsCached: true,
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
          const Offset(0, -500),
          500,
        );
        await tester.pumpAndSettle();

        expect(getRequestedChunkCount(), 2);
      });
    });
  });

  group('Should show error', () {
    testWidgets('page when fetching chunk fails', (tester) async {
      const failureText = 'expected failure';
      final widget = MaterialApp(
        home: Scaffold(
          body: PaginatedBuilder<Post, Post>(
            key: key,
            chunkDataLimit: 1,
            dataChunker: (Post? cursor, int limit) async {
              throw Exception(failureText);
            },
            itemBuilder: itemBuilder,
            afterPageLoadChangeStream: afterPageLoadChange.stream,
            rebuildListWhenChunkIsCached: true,
            listBuilder: listBuilder,
            enablePrintStatements: false,
          ),
        ),
      );

      await tester.pumpWidget(widget); // Shows loading widget
      await tester.pump(); // Runs builder
      await tester.pump(); // loads error

      expect(find.byType(DefaultErrorCard), findsOneWidget);
    });

    testWidgets('for each failing item', (tester) async {
      const failureText = 'expected failure';
      final allPosts = List.generate(5, (index) {
        final location = index + 1;
        return Post(id: location, title: 'post $location', body: 'post body');
      });

      final widget = MaterialApp(
        home: Scaffold(
          body: PaginatedBuilder<Post, Post>(
            key: key,
            // Make sure another request isn't needed to know we're at the
            // end of the list
            chunkDataLimit: 1,
            rebuildListWhenChunkIsCached: true,
            dataChunker: (cursor, limit) =>
                handleGetNext(allPosts, cursor, limit),
            itemBuilder: (
              BuildContext context,
              ItemData<Post> data, [
              Animation<double>? animation,
            ]) =>
                throw Exception(failureText),
            afterPageLoadChangeStream: afterPageLoadChange.stream,
            listBuilder: listBuilder,
            enablePrintStatements: false,
          ),
        ),
      );

      await tester.pumpWidget(widget); // Shows loading widget
      await tester.pumpAndSettle();

      expect(find.byType(DefaultErrorCard), findsNWidgets(5));
    });
  });
}
