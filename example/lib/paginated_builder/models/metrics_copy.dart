import 'package:equatable/equatable.dart';
import 'package:example/l10n/l10n.dart';

class MetricsCopy extends Equatable {
  const MetricsCopy({
    required this.cachedItemLengthLabel,
    required this.chunkSizeLabel,
    required this.chunksRequestedLabel,
    required this.totalComparatorsLabel,
  });

  MetricsCopy.localized(AppLocalizations l10n)
      : chunkSizeLabel = l10n.builderMetricsChunkSizeLabel,
        cachedItemLengthLabel = l10n.builderMetricsCachedItemLengthLabel,
        chunksRequestedLabel = l10n.builderMetricsChunksRequestedLabel,
        totalComparatorsLabel = l10n.builderMetricsTotalComparatorsLabel;

  final String chunkSizeLabel;
  final String totalComparatorsLabel;
  final String chunksRequestedLabel;
  final String cachedItemLengthLabel;

  @override
  List<Object> get props => [
        chunkSizeLabel,
        totalComparatorsLabel,
        chunksRequestedLabel,
        cachedItemLengthLabel
      ];
}
