## 1.0.0

!Breaking:
- `SnapshotState.stable` is now `SnapshotState.added`
- `onItemReceived` callback now accepts a third positional argument for `SnapshotState`
  ### Before
  onItemReceived: (index, data) {...}

  ### After
  onItemReceived: (index, data, state) {...}
- feat: Update
  - Adds `SnapshotState.updated`
  - Adds `uniqueIdFinder` to `PaginatedSnapshot<T>`
    - Required when using `SnapshotState.updated` (will throw if not provided)

## 0.2.0

!Breaking:
Flutter/Dart version bump
dart: >= 3.0.0
Flutter: >= 3.10.0

- feat: Delete
  - Adds `PaginatedSnapshot<T>` to allow for deletion of items in paginators

## 0.1.0

- Initial release
