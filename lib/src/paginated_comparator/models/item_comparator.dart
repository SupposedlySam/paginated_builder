import 'package:equatable/equatable.dart';
import 'package:paginated_builder/src/paginated_comparator/models/item_data.dart';

export 'package:paginated_builder/src/paginated_comparator/models/item_data.dart';

/// Provides values used in the [PaginatedComparator.itemBuilder] method with
/// each iteration.
class ItemComparator<T> extends Equatable {
  const ItemComparator({
    required this.previousItem,
    required this.currentItem,
    required this.nextItem,
    required this.isFirstItem,
    required this.isLastItem,
  });

  final ItemData<T> previousItem;
  final ItemData<T> currentItem;
  final ItemData<T> nextItem;
  final bool isFirstItem;
  final bool isLastItem;

  T get previous => previousItem.item;
  T get current => currentItem.item;
  T get next => nextItem.item;

  @override
  List<Object?> get props => [
        previousItem,
        currentItem,
        nextItem,
        isFirstItem,
        isLastItem,
      ];
}
