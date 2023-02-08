import 'package:equatable/equatable.dart';

/// Provides values used in the [PaginatedComparator.itemBuilder] method with
/// each iteration.
class ItemData<T> extends Equatable {
  const ItemData({
    required this.item,
    required this.index,
  });

  final T item;
  final int index;

  @override
  List<Object?> get props => [item, index];
}
