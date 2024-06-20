import 'package:equatable/equatable.dart';

enum SnapshotState { added, deleted, updated }

base class PaginatedSnapshot<T> extends Equatable {
  const PaginatedSnapshot({
    required this.data,
    required this.state,
    this.uniqueIdFinder,
  });

  /// The data of the snapshot
  final T data;

  /// The state of the snapshot
  final SnapshotState state;

  /// The function to find the unique ID of the data
  ///
  /// This is used to replace the correct item in the list and must be provided
  /// if you want to use the [SnapshotState.updated] state.
  final dynamic Function(T)? uniqueIdFinder;

  @override
  List<Object?> get props => [state, data, uniqueIdFinder];
}
