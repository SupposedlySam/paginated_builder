import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';

typedef MaybeJson = Map<String, dynamic>?;
typedef ConvertedWidgetBuilder<T> = Widget Function(
  BuildContext context,
  ItemData<T> data, [
  Animation<double>? animation,
]);
typedef ComparableWidgetBuilder<T> = Widget Function(
  BuildContext context,
  ItemComparator<T> comparator, [
  Animation<double>? animation,
]);
typedef Converter<T> = T Function(MaybeJson);
typedef Paginator<DataType, CursorType> = Future<Chunk<DataType, CursorType>>
    Function(Chunk<DataType, CursorType> chunk);

typedef AnimatableIndexedWidgetBuilder = Widget Function(
  BuildContext context,
  int index, [
  Animation<double>? animation,
]);
typedef EnclosingWidgetBuilder = Widget Function(
  int initialItemCount,
  AnimatableIndexedWidgetBuilder paginatedItemBuilder,
);
typedef ItemReceivedCallback<T> = void Function(int, T);
typedef CursorSelector<DataType, CursorType> = CursorType Function(DataType);
typedef DefaultPaginatorBuilder<DataType, CursorType>
    = Paginator<DataType, CursorType> Function(
  CursorSelector<DataType, CursorType> cursorSelector,
  DataChunker<DataType, CursorType> dataChunker,
);
typedef ErrorWidgetBuilder = Widget Function(Object error);
