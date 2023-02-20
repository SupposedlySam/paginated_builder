import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ErrorWidgetBuilder;
import 'package:flutter/scheduler.dart';
import 'package:paginated_builder/paginated_builder.dart';

import 'package:paginated_builder/src/utils.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
abstract class PaginatedBase<DataType, CursorType> extends StatefulWidget {
  const PaginatedBase({
    required this.listBuilder,
    required this.cursorSelector,
    required this.dataChunker,
    this.afterPageLoadChangeStream = const Stream.empty(),
    this.thresholdPercent = PaginatedBase.defaultThresholdPercent,
    this.chunkDataLimit,
    this.onItemReceived,
    this.pageLoadingWidget = const DefaultPageLoadingView(),
    this.pageErrorWidgetBuilder,
    this.itemLoadingWidget = const DefaultBottomLoader(),
    this.itemErrorWidgetBuilder,
    this.emptyWidget = const DefaultEmptyView(),
    this.enablePrintStatements = kDebugMode,
    this.rebuildListWhenSourceChanges = false,
    this.rebuildListWhenChunkIsCached = false,
    this.onListRebuild,
    super.key,
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
  /// When items are added to this stream, they will be added to the cache and
  /// [onItemReceived] will be called.
  final Stream<DataType> afterPageLoadChangeStream;

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
  final ItemReceivedCallback<DataType>? onItemReceived;

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

  /// Pagination is based on the original data retrieved from the
  /// [afterPageLoadChangeStream]. When changes occur (new items are added to
  /// the stream)
  /// this value tells whether or not to re-render the entire list.
  final bool rebuildListWhenSourceChanges;

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
  /// for this data source. Alternatively, it is possible to also receive a null
  /// cursor if the
  ///
  /// The [limit] is the maximum amount of items the method expects to receive
  /// when being invoked.
  ///
  /// Warning: To avoid duplicate items, ensure you're getting the
  /// [limit] number of items AFTER the [cursor].
  final DataChunker<DataType, CursorType> dataChunker;
}

abstract class PaginatedBaseState<DataType, CursorType,
        StateType extends PaginatedBase<DataType, CursorType>>
    extends State<StateType> {
  final List<DataType> _cachedItems = <DataType>[];
  late Chunk<DataType, CursorType> lastRequestedChunk;
  late Chunk<DataType, CursorType> nextAvailableChunk;
  bool loading = false;
  StreamSubscription<DataType>? dataSourceChangesSub;
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

  Paginator<DataType, CursorType> defaultPaginatorBuilder(
    CursorSelector<DataType, CursorType> cursorSelector,
    DataChunker<DataType, CursorType> dataChunker,
  ) {
    return (Chunk<DataType, CursorType> chunk) async {
      // If we're passing back in the last value, immediately return.
      if (chunk.status == ChunkStatus.last) return chunk;

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
    _requestChunk(Chunk(limit: chunkLimit))
        .then(_updateView)
        .then(_listenForChanges);
  }

  /// Listen to a stream of items and insert them into the list
  void _listenForChanges(_) {
    dataSourceChangesSub ??=
        widget.afterPageLoadChangeStream.listen(_cacheStartAndNotify);
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

    return widget.listBuilder(cacheLength, paginatedItemBuilderWithEndLoader);
  }

  Future<void> _getNextChunk() async {
    if (lastRequestedChunk != nextAvailableChunk) {
      await _requestChunk(nextAvailableChunk);
    }
  }

  void _handleReceivedChunk(Chunk<DataType, CursorType> chunk) {
    conditionalPrint('paginated_builder: adding chunk to next available');
    conditionalPrint('paginated_builder: $chunk');
    nextAvailableChunk = chunk;
    if (nextAvailableChunk != lastRequestedChunk) {
      _chunksRequested++;
      chunk.data.forEach(_cacheEndAndNotify);
      if (widget.rebuildListWhenChunkIsCached) _updateView<DataType>();
    }
  }

  void _cacheEndAndNotify(DataType data) {
    _cachedItems.add(data);
    widget.onItemReceived?.call(cacheIndex, data);
  }

  void _cacheStartAndNotify(DataType data) {
    final shouldUpdateUI = _cachedItems.isEmpty;
    _cachedItems.insert(0, data);
    if (shouldUpdateUI || widget.rebuildListWhenSourceChanges) {
      _updateView<DataType>();
    }
    widget.onItemReceived?.call(0, data);
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
    Widget buildItemOrError() {
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

    return isAtEnd && nextChunkIsLoading
        ? widget.itemLoadingWidget!
        : buildItemOrError();
  }

  Future<void> getChunkIfInLastChunkAndPastThreshold(int index) async {
    final inLastChunk = index > lastCachedChunkStartingIndex;
    final hasMetThreshold = index >= requestThresholdIndex;

    conditionalPrint(
      'paginated_builder: index: $index, threshold: $requestThresholdIndex',
    );
    if (inLastChunk && hasMetThreshold) {
      conditionalPrint(
        'paginated_builder: in last chunk and has met threshold',
      );
      await _getNextChunk();
    }
  }

  Future<void> _requestChunk(Chunk<DataType, CursorType> chunk) async {
    conditionalPrint('paginated_builder: requesting chunk');
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

      final paginator = defaultPaginatorBuilder(
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

class DefaultErrorCard extends StatelessWidget {
  const DefaultErrorCard(
    this.error, {
    super.key,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.error,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class DefaultPageLoadingView extends StatelessWidget {
  const DefaultPageLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

class DefaultEmptyView extends StatelessWidget {
  const DefaultEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Nothing to see here'));
  }
}

class DefaultBottomLoader extends StatelessWidget {
  const DefaultBottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}
