import 'package:example/paginated_builder/models/models.dart';
import 'package:example/paginated_builder/view/basic_paginated_builder_page.dart';
import 'package:flutter/widgets.dart';

class BuilderMetrics extends StatelessWidget {
  const BuilderMetrics({
    required this.chunkCount,
    required this.copy,
    required this.itemCacheLength,
    super.key,
  });

  final int itemCacheLength;
  final int chunkCount;
  final MetricsCopy copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${copy.chunkSizeLabel} ${BasicPaginatedBuilderPage.chunkSize}',
            ),
            Text(
              '${copy.totalComparatorsLabel} '
              '${BasicPaginatedBuilderPage.itemCount}',
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${copy.chunksRequestedLabel} $chunkCount'),
            Text('${copy.cachedItemLengthLabel} $itemCacheLength'),
          ],
        ),
      ],
    );
  }
}
