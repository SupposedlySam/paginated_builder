## 1.0.1
- Account for race conditions when getting a chunk and listening for changes.
Previously, we got the chunk and then listened for changes after updating the UI. There was a chance that an update could have come in before we started listening, causing data to be missed. Now, we listen for changes before requesting the chunk and immediately pause the stream sub until after the UI is updated.
While the chunk is getting processed, any changes get queued and emitted once the UI updates.

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
