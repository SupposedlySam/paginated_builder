import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
class PaginatedComparator<DataType, CursorType>
    extends PaginatedBase<DataType, CursorType> {
  const PaginatedComparator({
    required super.listBuilder,
    required this.itemBuilder,
    required super.dataChunker,
    super.afterPageLoadChangeStream,
    super.chunkDataLimit,
    super.cursorSelector,
    super.emptyWidget,
    super.enablePrintStatements,
    super.key,
    super.itemLoadingWidget,
    super.pageLoadingWidget,
    super.itemErrorWidgetBuilder,
    super.pageErrorWidgetBuilder,
    super.onItemReceived,
    super.onListRebuild,
    super.rebuildListWhenChunkIsCached,
    super.rebuildListWhenSourceChanges,
    super.shouldShowItemLoader,
    super.thresholdPercent,
  });

  /// The item reducer is the same callback used with [ListView.builder] with
  /// one exception. Normally you receive an index, whereas with this
  /// [itemComparator] you receive two converted items instead of an index.
  /// The converted items are the previous item, the current item, and the
  /// next item.
  ///
  /// ### Scenarios
  /// #### First Item
  /// previous == current
  ///
  /// #### Last Item
  /// current == next
  ///
  /// #### Only 1 Item Available
  /// previous == current == next
  ///
  /// Items are retrieved from the in-memory cache located in the
  /// [PaginatedComparatorState.cachedItems] property of the State class.
  final ComparableWidgetBuilder<DataType> itemBuilder;

  @override
  PaginatedComparatorState<DataType, CursorType> createState() =>
      PaginatedComparatorState<DataType, CursorType>();
}

class PaginatedComparatorState<DataType, CursorType> extends PaginatedBaseState<
    DataType, CursorType, PaginatedComparator<DataType, CursorType>> {
  /// Contains the available index to be within bounds
  ///
  /// This prevents "OutOfRangeException"s being thrown when searching for the
  /// previous and next widget on a finite List
  int withinRange(int index) => index.clamp(0, cachedItems.length - 1);

  @override
  Widget paginatedItemBuilder(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]) {
    final previousItemIndex = withinRange(index - 1);
    final currentItemIndex = withinRange(index);
    final nextItemIndex = withinRange(index + 1);
    final comparator = ItemComparator(
      previousItem: ItemData(
        item: cachedItems[previousItemIndex],
        index: previousItemIndex,
      ),
      currentItem: ItemData(
        item: cachedItems[currentItemIndex],
        index: currentItemIndex,
      ),
      nextItem: ItemData(
        item: cachedItems[nextItemIndex],
        index: nextItemIndex,
      ),
      isFirstItem: index == 0,
      isLastItem: index == cacheIndex,
    );

    return widget.itemBuilder(context, comparator, animation);
  }
}
