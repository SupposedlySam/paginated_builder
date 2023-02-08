import 'package:example/app/app.dart';
import 'package:example/paginated_builder/view/basic_paginated_builder_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(BasicPaginatedBuilderPage), findsOneWidget);
    });
  });
}