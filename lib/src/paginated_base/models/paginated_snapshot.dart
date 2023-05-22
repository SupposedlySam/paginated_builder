import 'package:equatable/equatable.dart';

enum SnapshotState { stable, deleted }

base class PaginatedSnapshot<T> extends Equatable {
  const PaginatedSnapshot({
    required this.data,
    required this.state,
  });

  final T data;
  final SnapshotState state;

  @override
  List<Object?> get props => [state, data];
}
