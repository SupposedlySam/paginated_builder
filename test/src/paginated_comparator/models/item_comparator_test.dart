import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_builder/paginated_builder.dart';

void main() {
  test('should compare by value', () {
    expect(
      const ItemComparator<int>(
        previousItem: ItemData(item: 1, index: 0),
        currentItem: ItemData(item: 2, index: 0),
        nextItem: ItemData(item: 3, index: 0),
        isFirstItem: true,
        isLastItem: true,
      ),
      const ItemComparator<int>(
        previousItem: ItemData(item: 1, index: 0),
        currentItem: ItemData(item: 2, index: 0),
        nextItem: ItemData(item: 3, index: 0),
        isFirstItem: true,
        isLastItem: true,
      ),
    );

    expect(
      // ignore: prefer_const_constructors
      ItemComparator<int>(
        previousItem: const ItemData(item: 1, index: 0),
        currentItem: const ItemData(item: 2, index: 0),
        nextItem: const ItemData(item: 3, index: 0),
        isFirstItem: true,
        isLastItem: true,
      ),
      // ignore: prefer_const_constructors
      ItemComparator<int>(
        previousItem: const ItemData(item: 1, index: 0),
        currentItem: const ItemData(item: 2, index: 0),
        nextItem: const ItemData(item: 3, index: 0),
        isFirstItem: true,
        isLastItem: true,
      ),
    );
  });
}
