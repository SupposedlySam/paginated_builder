import 'package:flutter_test/flutter_test.dart';
import 'package:paginated_builder/paginated_builder.dart';

void main() {
  test('should compare by value', () {
    expect(
      const ItemComparator<int>(
        previous: 1,
        current: 2,
        next: 3,
        isFirstItem: true,
        isLastItem: true,
      ),
      const ItemComparator<int>(
        previous: 1,
        current: 2,
        next: 3,
        isFirstItem: true,
        isLastItem: true,
      ),
    );

    expect(
      // ignore: prefer_const_constructors
      ItemComparator<int>(
        previous: 1,
        current: 2,
        next: 3,
        isFirstItem: true,
        isLastItem: true,
      ),
      // ignore: prefer_const_constructors
      ItemComparator<int>(
        previous: 1,
        current: 2,
        next: 3,
        isFirstItem: true,
        isLastItem: true,
      ),
    );
  });
}
