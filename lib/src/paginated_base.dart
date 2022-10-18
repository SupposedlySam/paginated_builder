import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_builder/paginated_builder.dart';

/// Manages caching and retrieval of [Chunk]s using the provided [paginator].
///
/// Commonly used as a wrapper around [ListView.builder].
abstract class PaginatedBase<DataType, CursorType> extends StatefulWidget {
  static const double defaultThresholdPercent = 0.7;

  /// Optional replacement for  the loading widget displayed before the first
  /// chunk is loaded.
  final Widget? loadingWidget;

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
  /// The [AnimatableIndexedWidgetBuilder] is the paginated item builder provided by this
  /// widget. Use it as a direct replacement for any regular or animated itemBuilder.
  final EnclosingWidgetBuilder listBuilder;

  /// Invoked when data from a new chunk is received
  ///
  /// The callback will be called for every item received in each chunk
  final ItemReceivedCallback<DataType>? onItemReceived;

  /// Used to limit the amount of data returned with each chunk
  final int? chunkDataLimit;

  /// Whether to enable print statements or not
  ///
  /// Normally set to use [kIsDebug] so logs are printed while you're working,
  /// but not in production
  final bool enablePrintStatements;

  /// Pagination is based on the original data retrieved from the
  /// [afterPageLoadChangeStream]. When changes occur (new items are added to the stream)
  /// this value tells whether or not to re-render the entire list.
  final bool refreshListWhenSourceChanges;

  final CursorSelector<DataType, CursorType> cursorSelector;
  final DataChunker<DataType, CursorType> dataChunker;

  const PaginatedBase({
    required this.listBuilder,
    required this.cursorSelector,
    required this.dataChunker,
    this.afterPageLoadChangeStream = const Stream.empty(),
    this.thresholdPercent = PaginatedBase.defaultThresholdPercent,
    this.chunkDataLimit,
    this.onItemReceived,
    this.loadingWidget,
    this.emptyWidget,
    this.enablePrintStatements = kDebugMode,
    this.refreshListWhenSourceChanges = true,
    Key? key,
  })  : assert(thresholdPercent > 0.0),
        assert(thresholdPercent <= 1.0),
        super(key: key);
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
    if (mounted) setState(() {});
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
    if (isLoading) {
      return widget.loadingWidget ?? const DefaultLoadingView();
    } else if (cachedItems.isEmpty) {
      return widget.emptyWidget ?? const DefaultEmptyView();
    }

    return widget.listBuilder(cacheLength, paginatedItemBuilder);
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
    }
  }

  void _cacheEndAndNotify(DataType data) {
    _cachedItems.add(data);
    widget.onItemReceived?.call(cacheIndex, data);
  }

  void _cacheStartAndNotify(DataType data) {
    final shouldUpdateUI = _cachedItems.isEmpty;
    _cachedItems.insert(0, data);
    if (shouldUpdateUI || widget.refreshListWhenSourceChanges) _updateView();
    widget.onItemReceived?.call(0, data);
  }

  Widget paginatedItemBuilder(
    BuildContext context,
    int index, [
    Animation<double>? animation,
  ]);

  void getChunkIfInLastChunkAndPastThreshold(int index) {
    final inLastChunk = index > lastCachedChunkStartingIndex;
    final hasMetThreshold = index >= requestThresholdIndex;

    conditionalPrint(
      'paginated_builder: index: $index, threshold: $requestThresholdIndex',
    );
    if (inLastChunk && hasMetThreshold) {
      conditionalPrint(
        'paginated_builder: in last chunk and has met threshold',
      );
      _getNextChunk();
    }
  }

  Future<void> _requestChunk(Chunk<DataType, CursorType> chunk) async {
    conditionalPrint('paginated_builder: requesting chunk');
    try {
      loading = true;

      lastRequestedChunk = chunk;

      final paginator = defaultPaginatorBuilder(
        widget.cursorSelector,
        widget.dataChunker,
      );

      final result = await paginator(chunk).then(_handleReceivedChunk);

      loading = false;
      return result;
    } catch (e) {
      loading = false;

      rethrow;
    }
  }

  void conditionalPrint(String message) {
    if (widget.enablePrintStatements) {
      // ignore: avoid_print
      print(message);
    }
  }
}

class DefaultLoadingView extends StatelessWidget {
  const DefaultLoadingView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

class DefaultEmptyView extends StatelessWidget {
  const DefaultEmptyView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Nothing to see here'));
  }
}
