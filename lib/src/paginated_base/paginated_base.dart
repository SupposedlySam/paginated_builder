import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ErrorWidgetBuilder;
import 'package:flutter/scheduler.dart';
import 'package:paginated_builder/paginated_builder.dart';
import 'package:paginated_builder/src/paginated_base/widgets/widgets.dart';
import 'package:paginated_builder/src/utils.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
abstract base class PaginatedBase<DataType, CursorType> extends StatefulWidget {
  const PaginatedBase({
    required this.dataChunker,
    required this.listBuilder,
    super.key,
    this.listStartChangeStream = const Stream.empty(),
    this.chunkDataLimit,
    this.cursorSelector,
    this.emptyWidget = const DefaultEmptyView(),
    this.enablePrintStatements = kDebugMode,
    this.itemErrorWidgetBuilder,
    this.itemLoadingWidget = const DefaultBottomLoader(),
    this.onItemReceived,
    this.onListRebuild,
    this.pageErrorWidgetBuilder,
    this.pageLoadingWidget = const DefaultPageLoadingView(),
    this.rebuildListWhenChunkIsCached = false,
    this.rebuildListWhenStreamHasChanges = false,
    this.shouldAutoLoadNextChunk = true,
    this.shouldShowItemLoader = true,
    this.thresholdPercent = PaginatedBase.defaultThresholdPercent,
  })  : assert(
          thresholdPercent > 0.0,
          'threshold should be greater than 0',
        ),
        assert(
          thresholdPercent <= 1.0,
          'threshold should be less than or equal to 1',
        );

  /// The default value used to define how far the user can scroll before the
  /// next chunk of data is retrieved.
  static const double defaultThresholdPercent = 0.7;

  /// Optional replacement for the loading widget displayed before the first
  /// chunk is loaded.
  ///
  /// Defaults to use [DefaultPageLoadingView]
  final Widget? pageLoadingWidget;

  /// Optional replacement for the error widget displayed when getting the
  /// next chunk fails
  ///
  /// Defaults to use the [DefaultErrorCard]
  final ErrorWidgetBuilder? pageErrorWidgetBuilder;

  /// Optional replacement for the loading widget displayed at the end of the
  /// list while the next chunk is loading.
  ///
  /// The loading widget will replace the last item in the list until the new
  /// chunk of items are loaded. The last item will load in when there are no
  /// more available chunks.
  ///
  /// Defaults to use [DefaultBottomLoader]
  final Widget? itemLoadingWidget;

  /// Optional replacement for the error widget displayed when calling the
  /// paginatedItemBuilder fails
  ///
  /// Defaults to use the [DefaultErrorCard]
  final ErrorWidgetBuilder? itemErrorWidgetBuilder;

  /// Optional replacement for the empty widget displayed when we've finished
  /// loading the first chunk and there are still no items
  final Widget? emptyWidget;

  /// How far the user should be able to scroll into the last chunk before a
  /// new chunk is requested.
  ///
  /// This value should be 0.0 exclusive to 1.0 inclusive.
  final double thresholdPercent;

  /// The stream listened to once the initial page load happens.
  ///
  /// When items are added to this stream, they will be added to the beginning
  /// of the cache and [onItemReceived] will be called with a zero index.
  final Stream<PaginatedSnapshot<DataType>> listStartChangeStream;

  /// The function used to generate the widget shown when items exist in the
  /// cache.
  ///
  /// Commonly a [ListView.builder] Widget will be returned as you can directly
  /// replace `ListView`s required `itemBuilder` argument with the provided
  /// paginatedItemBuilder parameter.
  ///
  /// ### Param
  /// The [AnimatableIndexedWidgetBuilder] is the paginated item builder
  /// provided by this widget. Use it as a direct replacement for any
  /// regular or animated itemBuilder.
  final EnclosingWidgetBuilder listBuilder;

  /// Invoked when data from a new chunk is received
  ///
  /// The callback will be called for every item received in each chunk
  final ItemReceivedCallback<DataType?>? onItemReceived;

  /// Invoked when the list rebuilds
  ///
  /// The callback will be called for every rebuild of the list
  final void Function()? onListRebuild;

  /// Used to limit the amount of data returned with each chunk
  final int? chunkDataLimit;

  /// Whether to enable print statements or not
  ///
  /// Normally set to use [kIsDebug] so logs are printed while you're working,
  /// but not in production
  final bool enablePrintStatements;

  /// Whether to recreate the the Widget provided in the [listBuilder] after a
  /// change comes through on the [listStartChangeStream].
  final bool rebuildListWhenStreamHasChanges;

  /// Whether to recreate the Widget provided in the [listBuilder] when items
  /// from a new chunk is added to the in-memory cache
  ///
  /// By default, the list created by the [listBuilder] is only ever built once
  /// on initialization. Every time the list is re-built, all items need to be
  /// recreated using the item builder. Therefore, it is recommended to use a
  /// list that allows you to add in the items as they come in through the
  /// [onItemReceived] callback.
  ///
  /// However, when using a standard [ListView], there is no mechanism to insert
  /// items into the list without rebuilding the entire list. Because of this,
  /// you can set this value to `true` and the list will re-initialize with all
  /// of the cached items retrieved so far.
  ///
  /// It's recommended to use a [AnimatedList] to insert and removes items from
  /// the state using a [GlobalKey] or the static `of` method (see
  /// AnimatedList's doc comments for details).
  final bool rebuildListWhenChunkIsCached;

  /// Whether to replace the last item in the list with a loading Widget when a
  /// new chunk is being retrieved.
  ///
  /// Defaults to `true`
  ///
  /// See: [itemLoadingWidget] to use a custom Widget as the loader
  final bool shouldShowItemLoader;

  /// Whether to automatically load the next chunk of data when the threshold
  /// is met and more are available
  ///
  /// Defaults to `true`
  ///
  /// The [PaginatedBaseState.getChunkIfInLastChunkAndPastThreshold] method will
  /// need to be manually invoked from your State Widget if this is set to
  /// `false`.
  ///
  /// See [PaginatedBuilder] for an example of how to extend this class
  /// correctly
  final bool shouldAutoLoadNextChunk;

  /// Used to select the value to passed into the [dataChunker] the next time
  /// it's called.
  ///
  /// The cursor will come from the last item in the data returned by the
  /// [dataChunker]. The cursor should be used to skip any records previously
  /// retrieved before getting the next `n` records. `n` being the number of
  /// records specified by the limit provided to the [dataChunker] callback.
  final CursorSelector<DataType, CursorType>? cursorSelector;

  /// Called to retrieve the next `n` number of items from your data source.
  ///
  /// Use the provided [cursor] and [limit] to skip and get the next 'n' number
  /// of items. The cursor will be the identifier selected using the
  /// [cursorSelector] from the last time the [getNext] method was called.
  ///
  /// If the [cursor] is `null`, this is the first time the method is being run
  /// for this data source.
  ///
  /// The [limit] is the maximum amount of items the method expects to receive
  /// when being invoked.
  ///
  /// Warning: To avoid duplicate items, ensure you're getting the
  /// [limit] number of items AFTER the [cursor].
  final DataChunker<DataType, CursorType> dataChunker;
}

abstract base class PaginatedBaseState<DataType, CursorType,
        StateType extends PaginatedBase<DataType, CursorType>>
    extends State<StateType> {
  final List<DataType> _cachedItems = <DataType>[];
  late Chunk<DataType, CursorType> lastRequestedChunk;
  late Chunk<DataType, CursorType> nextAvailableChunk;
  bool loading = false;
  StreamSubscription<PaginatedSnapshot<DataType>>? dataSourceChangesSub;
  int _chunksRequested = 0;

  List<DataType> get cachedItems => _cachedItems;

  int get cacheLength => _cachedItems.length;
  int get cacheIndex => cacheLength - 1;
  int get lastCachedChunkStartingIndex => max(cacheIndex - limit, 0);
  int get limit => lastRequestedChunk.limit;
  int get requestThresholdIndex =>
      (cacheIndex * widget.thresholdPercent).floor();
  int get chunksRequested => _chunksRequested;
  Widget? pageErrorWidget;

  Paginator<DataType, CursorType> paginatorBuilder(
    CursorSelector<DataType, CursorType> cursorSelector,
    DataChunker<DataType, CursorType> dataChunker,
  ) {
    return (Chunk<DataType, CursorType> chunk) async {
      // If we're passing back in the last value, immediately return.
      if (chunk.status == ChunkStatus.last) return chunk;

      _chunksRequested++;

      conditionalPrint(
        'paginated_builder: making request for chunk at cursor ${chunk.cursor}',
      );

      return Chunker<DataType, CursorType>(
        cursorSelector: cursorSelector,
        dataChunker: dataChunker,
      ).getNext(chunk);
    };
  }

  @override
  void initState() {
    super.initState();
    final chunkLimit = widget.chunkDataLimit ?? Chunk.defaultLimit;
    dataSourceChangesSub ??= _listenForChanges()..pause();
    _requestChunk(Chunk(limit: chunkLimit))
        .then(_updateView)
        .then((_) => dataSourceChangesSub?.resume());
  }

  /// Listen to a stream of items and insert them into the list
  StreamSubscription<PaginatedSnapshot<DataType>> _listenForChanges() {
    return widget.listStartChangeStream.listen((snap) {
      switch (snap.state) {
        case SnapshotState.added:
          _cacheStartAndNotify(snap.data, snap.state);
        case SnapshotState.updated:
          _replaceItemAndNotify(snap);
        case SnapshotState.deleted:
          _removeItemAndNotify(snap.data);
      }
    });
  }

  void _updateView<T>([T? _]) {
    if (mounted) {
      if (widget.onListRebuild != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.onListRebuild!();
        });
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    dataSourceChangesSub?.cancel();
    dataSourceChangesSub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = loading && cachedItems.isEmpty;
    if (pageErrorWidget != null) {
      return pageErrorWidget!;
    } else if (isLoading) {
      return widget.pageLoadingWidget!;
    } else if (cachedItems.isEmpty) {
      return widget.emptyWidget!;
    }

    return widget.listBuilder(
      cacheLength,
      (context, index, [animation]) {
        if (widget.shouldAutoLoadNextChunk) {
          getChunkIfInLastChunkAndPastThreshold(index);
        }

        return paginatedItemBuilderWithEndLoader(context, index, animation);
      },
    );
  }

  Future<void> _getNextChunk() async {
    if (lastRequestedChunk != nextAvailableChunk) {
      await _requestChunk(nextAvailableChunk);
    }
  }

  void _handleReceivedChunk(Chunk<DataType, CursorType> chunk) {
    conditionalPrint('paginated_builder: Next available is $chunk');
    nextAvailableChunk = chunk;
    if (nextAvailableChunk != lastRequestedChunk) {
      // ignore: avoid_function_literals_in_foreach_calls
      chunk.data.forEach(
        (data) => _cacheEndAndNotify(data, SnapshotState.added),
      );
      if (widget.rebuildListWhenChunkIsCached) _updateView<DataType>();
    }
  }

  void _cacheEndAndNotify(DataType data, SnapshotState state) {
    _cachedItems.add(data);
    widget.onItemReceived?.call(cacheIndex, data, state);
  }

  void _cacheStartAndNotify(DataType data, SnapshotState state) {
    final shouldUpdateUI = _cachedItems.isEmpty;

    _cachedItems.insert(0, data);
    if (shouldUpdateUI || widget.rebuildListWhenStreamHasChanges) {
      _updateView<DataType>();
    }
    widget.onItemReceived?.call(0, data, state);
  }

  void _removeItemAndNotify(DataType data) {
    final itemIndex = _cachedItems.indexOf(data);
    final wasRemoved = _cachedItems.remove(data);

    if (wasRemoved) {
      if (widget.rebuildListWhenStreamHasChanges) _updateView<DataType>();
      widget.onItemReceived?.call(itemIndex, null, SnapshotState.deleted);
    }
  }

  void _replaceItemAndNotify(PaginatedSnapshot<DataType> snap) {
    if (snap.uniqueIdFinder == null) {
      throw Exception(
        'You must provide a `uniqueIdFinder` when using the `updated` state',
      );
    }
    final data = snap.data;

    final itemIndex = _cachedItems.indexWhere(
      (item) =>
          snap.uniqueIdFinder!.call(item) == snap.uniqueIdFinder!.call(data),
    );
    if (itemIndex == -1) return;

    _cachedItems[itemIndex] = data;
    if (widget.rebuildListWhenStreamHasChanges) _updateView<DataType>();
    widget.onItemReceived?.call(itemIndex, data, SnapshotState.updated);
  }

  Widget paginatedItemBuilder(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]);

  Widget paginatedItemBuilderWithEndLoader(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]) {
    final itemLocation = index + 1;
    final isAtEnd = itemLocation == _cachedItems.length;
    final nextChunkIsLoading = nextAvailableChunk.status != ChunkStatus.last;

    /// Builds the item from user code or shows an error widget
    Widget buildGuardedItem() {
      try {
        return paginatedItemBuilder(
          context,
          index,
          animation,
        );
      } catch (e) {
        return widget.itemErrorWidgetBuilder?.call(e) ?? DefaultErrorCard(e);
      }
    }

    return isAtEnd && nextChunkIsLoading && widget.shouldShowItemLoader
        ? widget.itemLoadingWidget!
        : buildGuardedItem();
  }

  Future<void> getChunkIfInLastChunkAndPastThreshold(int index) async {
    final hasLimitOf1 = limit == 1;
    final inLastChunk = index > lastCachedChunkStartingIndex;
    final hasMetThreshold = index >= requestThresholdIndex;

    conditionalPrint(
      'paginated_builder: index: $index, threshold: $requestThresholdIndex',
    );
    if ((hasLimitOf1 || inLastChunk) && hasMetThreshold) {
      conditionalPrint(
        'paginated_builder: in last chunk and has met threshold',
      );
      await _getNextChunk();
    }
  }

  Future<void> _requestChunk(Chunk<DataType, CursorType> chunk) async {
    try {
      loading = true;
      pageErrorWidget = null;

      lastRequestedChunk = chunk;

      if (widget.cursorSelector == null &&
          typeOf<DataType>() != typeOf<CursorType>()) {
        throw Exception(
          'You must provide a `cursorSelector` when your `DataType` and'
          " `CursorType` don't match",
        );
      }

      final paginator = paginatorBuilder(
        widget.cursorSelector ?? (value) => value as CursorType,
        widget.dataChunker,
      );

      final result = await paginator(chunk).then(_handleReceivedChunk);

      loading = false;
      return result;
    } catch (e) {
      loading = false;
      final errorWidget =
          widget.pageErrorWidgetBuilder?.call(e) ?? DefaultErrorCard(e);

      setState(() => pageErrorWidget = errorWidget);
    }
  }

  void conditionalPrint(String message) {
    if (widget.enablePrintStatements) {
      // ignore: avoid_print
      print(message); // coverage:ignore-line
    }
  }
}
