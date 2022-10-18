import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base.dart';

import '../../models/post.dart';

void main() {
  final GlobalKey<PaginatedBaseState> key = GlobalKey<PaginatedBaseState>();
  late Widget widget;
  late List<Post> allPosts;
  Map<int, ItemComparator<Post>> comparators = <int, ItemComparator<Post>>{};

  Widget itemBuilder(
    BuildContext context,
    ItemComparator<Post> comparator, [
    Animation<double>? animation,
  ]) {
    comparators[comparator.current.id] = comparator;
    Widget toColumn(Post post, String position) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        key: Key('${post.id}_$position'),
        children: [Text(post.title), Text(post.id.toString()), Text(post.body)],
      );
    }

    return Row(
      children: [
        toColumn(comparator.previous, "previous"),
        toColumn(comparator.current, "current"),
        toColumn(comparator.next, "next"),
      ],
    );
  }

  Widget listBuilder(initialItemCount, paginatedItemBuilder) {
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
        body: PaginatedComparator<Post, Post>(
          key: key,
          chunkDataLimit: 1,
          dataChunker: handleGetNext,
          itemBuilder: itemBuilder,
          listBuilder: listBuilder,
          enablePrintStatements: false,
        ),
      ),
    );
  });

  testWidgets('should render previous, next, current', (tester) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('1_previous')), findsOneWidget);
    expect(find.byKey(const Key('1_current')), findsOneWidget);
    expect(find.byKey(const Key('1_next')), findsOneWidget);
  });

  testWidgets('first item prev & current should match', (tester) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final comparator = comparators[1]!;

    expect(comparator.previous, comparator.current);
  });

  testWidgets('first item current & next should match', (tester) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final lastComparatorKey = comparators.keys.last;
    final comparator = comparators[lastComparatorKey]!;

    expect(comparator.current, comparator.next);
  });

  testWidgets('only item prev & current & next should match', (tester) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: PaginatedComparator<Post, Post>(
          key: key,
          chunkDataLimit: 10,
          dataChunker: handleGetNext,
          itemBuilder: itemBuilder,
          listBuilder: listBuilder,
          enablePrintStatements: false,
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    assert(comparators.keys.length > 1);

    final firstComparatorKey = comparators.keys.first;
    final firstComparator = comparators[firstComparatorKey]!;

    expect(firstComparator.previous, firstComparator.current);
    expect(firstComparator.current, isNot(firstComparator.next));

    final lastComparatorKey = comparators.keys.last;
    final lastComparator = comparators[lastComparatorKey]!;

    expect(lastComparator.previous, isNot(lastComparator.current));
    expect(lastComparator.current, lastComparator.next);
  });
}
