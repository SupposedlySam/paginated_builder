import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
class PaginatedBuilder<DataType, CursorType>
    extends PaginatedBase<DataType, CursorType> {
  /// The item builder is the same callback used with [ListView.builder] with
  /// one exception. Normally you receive an index, whereas with this
  /// [itemBuilder] you receive your converted item at that index instead.
  ///
  /// This item is retrieved from the in-memory cache located in the
  /// [PaginatedBuilderState.cachedItems] property of the State class.
  final ConvertedWidgetBuilder<DataType> itemBuilder;
  const PaginatedBuilder({
    required this.itemBuilder,
    required Paginator<DataType, CursorType> paginator,
    required Stream<DataType> changesOnDataSource,
    required EnclosingWidgetBuilder listBuilder,
    double thresholdPercent = PaginatedBase.defaultThresholdPercent,
    Widget? loadingWidget,
    Widget? emptyWidget,
    ItemReceivedCallback<DataType>? onItemReceived,
    Key? key,
    bool enablePrintStatements = kDebugMode,
  }) : super(
          changesOnDataSource: changesOnDataSource,
          emptyWidget: emptyWidget,
          enablePrintStatements: enablePrintStatements,
          listBuilder: listBuilder,
          paginator: paginator,
          key: key,
          loadingWidget: loadingWidget,
          thresholdPercent: thresholdPercent,
          onItemReceived: onItemReceived,
        );

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
