import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
class PaginatedComparator<DataType, CursorType>
    extends PaginatedBase<DataType, CursorType> {
  /// The item reducer is the same callback used with [ListView.builder] with
  /// one exception. Normally you receive an index, whereas with this
  /// [itemComparator] you receive two converted items instead of an index. The converted items are the previous item, the current item, and the next item.
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
  /// [_PaginatedComparatorState.cachedItems] property of the State class.
  final ComparableWidgetBuilder<DataType> itemBuilder;

  const PaginatedComparator({
    required this.itemBuilder,
    required Paginator<DataType, CursorType> paginator,
    required Stream<DataType> changesOnDataSource,
    required EnclosingWidgetBuilder listBuilder,
    double thresholdPercent = PaginatedBase.defaultThresholdPercent,
    Widget? loadingWidget,
    Widget? emptyWidget,
    int? chunkDataLimit,
    ItemReceivedCallback<DataType>? onItemReceived,
    Key? key,
    bool enablePrintStatements = kDebugMode,
  }) : super(
          changesOnDataSource: changesOnDataSource,
          emptyWidget: emptyWidget,
          enablePrintStatements: enablePrintStatements,
          limit: chunkDataLimit,
          listBuilder: listBuilder,
          paginator: paginator,
          key: key,
          loadingWidget: loadingWidget,
          thresholdPercent: thresholdPercent,
          onItemReceived: onItemReceived,
        );

  @override
  _PaginatedComparatorState<DataType, CursorType> createState() =>
      _PaginatedComparatorState<DataType, CursorType>();
}

class _PaginatedComparatorState<DataType, CursorType>
    extends PaginatedBaseState<DataType, CursorType,
        PaginatedComparator<DataType, CursorType>> {
  /// Contains the available index to be within bounds
  ///
  /// This prevents "OutOfRangeException"s being thrown when searching for the
  /// previous and next widget on a finite List
  int withinRange(index) => index.clamp(0, cachedItems.length - 1);

  @override
  Widget paginatedItemBuilder(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]) {
    final comparator = ItemComparator(
      previous: cachedItems[withinRange(index - 1)],
      current: cachedItems[withinRange(index)],
      next: cachedItems[withinRange(index + 1)],
      isFirstItem: index == 0,
      isLastItem: index == cacheIndex,
    );

    super.getChunkIfInLastChunkAndPastThreshold(index);

    return widget.itemBuilder(context, comparator, animation);
  }
}
