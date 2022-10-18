import 'package:equatable/equatable.dart';

/// Provides values used in the [PaginatedComparator.itemBuilder] method with
/// each iteration.
class ItemComparator<T> extends Equatable {
  const ItemComparator({
    required this.previous,
    required this.current,
    required this.next,
    required this.isFirstItem,
    required this.isLastItem,
  });

  final T previous;
  final T current;
  final T next;
  final bool isFirstItem;
  final bool isLastItem;

  @override
  List<Object?> get props => [previous, current, next, isFirstItem, isLastItem];
}
