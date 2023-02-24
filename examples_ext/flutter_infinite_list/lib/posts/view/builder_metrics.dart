import 'package:flutter/widgets.dart';

import '../models/metrics_copy.dart';
import 'posts_page.dart';

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
              '${copy.chunkSizeLabel} ${PostsPage.chunkSize}',
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
