import 'package:equatable/equatable.dart';

class MetricsCopy extends Equatable {
  const MetricsCopy({
    required this.cachedItemLengthLabel,
    required this.chunkSizeLabel,
    required this.chunksRequestedLabel,
    required this.totalComparatorsLabel,
  });

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
