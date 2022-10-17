import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';

typedef MaybeJson = Map<String, dynamic>?;
typedef ConvertedWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T item, [
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
