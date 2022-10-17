import 'dart:async';
import 'dart:math';

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

  /// The callback used to request the next chunk and convert the returned json
  /// into an object of your choosing.
  ///
  /// ### Params
  /// The [Chunk] should have the cursor to begin from and the limit of items to
  /// retrieve after the cursor.
  ///
  /// The [Converter] simply takes in json and returns an item of your choosing.
  final Paginator<DataType, CursorType> paginator;

  /// The stream listened to once the initial page load happens.
  ///
  /// When items are added to this stream, they will be added to the cache and
  /// [onItemReceived] will be called.
  final Stream<DataType> changesOnDataSource;

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
  final int? limit;

  /// Whether to enable print statements or not
  ///
  /// Normally set to use [kIsDebug] so logs are printed while you're working,
  /// but not in production
  final bool enablePrintStatements;

  const PaginatedBase({
    required this.listBuilder,
    required this.paginator,
    required this.changesOnDataSource,
    required this.thresholdPercent,
    this.limit,
    this.onItemReceived,
    this.loadingWidget,
    this.emptyWidget,
    this.enablePrintStatements = false,
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

  List<DataType> get cachedItems => _cachedItems;

  int get cacheLength => _cachedItems.length;
  int get cacheIndex => cacheLength - 1;
  int get lastCachedChunkStartingIndex => max(cacheIndex - limit, 0);
  int get limit => lastRequestedChunk.limit;
  int get requestThresholdIndex =>
      (cacheIndex * widget.thresholdPercent).floor();

  @override
  void initState() {
    super.initState();
    final chunkLimit = widget.limit ?? Chunk.defaultLimit;
    _requestChunk(Chunk(limit: chunkLimit))
        .then(_updateView)
        .then(_listenForChanges);
  }

  /// Listen to a stream of items and insert them into the list
  void _listenForChanges(_) {
    dataSourceChangesSub ??=
        widget.changesOnDataSource.listen(_cacheStartAndNotify);
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
      return widget.loadingWidget ?? _defaultLoadingWidget();
    } else if (cachedItems.isEmpty) {
      return widget.emptyWidget ?? _defaultEmptyWidget();
    }

    return widget.listBuilder(cacheLength, paginatedItemBuilder);
  }

  Widget _defaultEmptyWidget() {
    return const Center(child: Text('Nothing to see here'));
  }

  Widget _defaultLoadingWidget() {
    return const Center(child: CircularProgressIndicator.adaptive());
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
    if (shouldUpdateUI) _updateView();
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

      final result = await widget.paginator(chunk).then(_handleReceivedChunk);

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
