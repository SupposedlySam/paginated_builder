import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
class PaginatedBuilder<DataType, CursorType>
    extends PaginatedBase<DataType, CursorType> {

  const PaginatedBuilder({
    required super.listBuilder,
    required this.itemBuilder,
    required super.dataChunker,
    super.cursorSelector,
    super.chunkDataLimit,
    super.afterPageLoadChangeStream,
    super.thresholdPercent,
    super.loadingWidget,
    super.emptyWidget,
    super.onItemReceived,
    super.key,
    super.enablePrintStatements,
    super.refreshListWhenSourceChanges,
  });
  /// The item builder is the same callback used with [ListView.builder] with
  /// one exception. Normally you receive an index, whereas with this
  /// [itemBuilder] you receive your converted item at that index instead.
  ///
  /// This item is retrieved from the in-memory cache located in the
  /// [PaginatedBuilderState.cachedItems] property of the State class.
  final ConvertedWidgetBuilder<DataType> itemBuilder;

  @override
  PaginatedBuilderState<DataType, CursorType> createState() =>
      PaginatedBuilderState<DataType, CursorType>();
}

class PaginatedBuilderState<DataType, CursorType> extends PaginatedBaseState<
    DataType, CursorType, PaginatedBuilder<DataType, CursorType>> {
  @override
  Widget paginatedItemBuilder(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]) {
    super.getChunkIfInLastChunkAndPastThreshold(index);

    return widget.itemBuilder(context, cachedItems[index], animation);
  }
}
