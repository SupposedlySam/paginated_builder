# Paginated Builder

A set of Widgets to paginate through data from any data source!

## Widget Features

### Paginated Builder

The most basic Widget in this package contains the following features.

- Select your own List Widget (`ListView.builder`, `AnimatableIndexedWidgetBuilder`, your custom built Widget, etc.)
- Use your own Widgets for each item
- Work with item data, not indexes
- Easily integrates with your API or provide pagination logic for local data
- Get notified when the list rebuilds or items are received
- Replaceable default Widgets for empty, loading, and error states
- Automatic item loader while new data loads
- Debuggable print statements
- Specify your chunk limit (how many items you want back at a time)
- Specify when a new chunk gets requested by setting a threshold
- Insert items into both sides of the list (`listStartChangeStream`)

### Paginated Comparator

Sometimes you just want to know item came before, and after your current item. With the Paginated Comparator, this is all done for you!

_Note: the first item's `previous` value will be the same as the `current`, and the last item's `next` will be the same as `current`._

- All the same features as the Paginated Builder
- Access previous, current and next items in the current item's builder

## Let me see it!

### Pagination Metadata

Data chunking is the mechanism used to paginate. Provide a limit (defaults to 50) and watch as chunks roll in!

<img src="https://user-images.githubusercontent.com/27933222/221288305-d53df808-27a2-4eaa-a0bd-60788cfc890a.gif" width=350 />

_Note: pagination metadata can be accessed directly through a `GlobalKey` (see examples)_

### Available Pagination Widgets

| Paginated Builder                                                                                                             | Paginated Comparator                                                                                                          |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://user-images.githubusercontent.com/27933222/221290838-055531d8-db68-4d64-9b1d-c34a340e9db9.gif" width=350 /> | <img src="https://user-images.githubusercontent.com/27933222/221290165-6332be03-7d7c-46e4-b705-92baf381a336.gif" width=350 /> |

### Error States

Basic error widgets are provided, but it's highly suggested to implement your own custom error widgets.

#### Your Custom Error Widgets

| Item Error                                                                                                                    | Page Error                                                                                                                    |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://user-images.githubusercontent.com/27933222/221238177-c212a47b-91a4-4108-a2a1-5dd9192c63ae.png" width=350 /> | <img src="https://user-images.githubusercontent.com/27933222/221236386-72e09881-99d9-40e1-b705-378b0d2b2360.png" width=350 /> |

### Loading State

Adaptive defaults are provided, but it's highly suggested to implement your own custom loading widgets.

#### Your Custom Loading Widgets

| Item Loader                                                                                                                   | Page Loader                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://user-images.githubusercontent.com/27933222/221258288-9b5f1417-6670-4a83-8f67-da6349a07bd3.gif" width=350 /> | <img src="https://user-images.githubusercontent.com/27933222/221258334-12eb2aab-dc0f-477e-aa6e-ea830f73d6be.gif" width=350 /> |

Custom loaders in the examples are courtesy of the [shimmer example](https://pub.dev/packages/shimmer) package.

### Empty State

A very basic default is provided, but it's highly suggested to implement your own custom empty widget.

#### Your Custom Empty State

<img src="https://user-images.githubusercontent.com/27933222/221280900-4a64e78a-02d3-4e41-9edf-4e0d84923e45.png" width=350 />

## Getting started

Install the latest version of the package with `flutter pub add paginated_builder`
Use the `PaginatedBuilder` or `PaginatedComparator` and provide the required arguments.

### Usage

#### Paginated Builder with an API

This is going to be the most common use case for this package. See the extended examples in the repo for an example using `bloc` and the JSON placeholder API.

##### API Integration

Your API must support pagination for this to work. Integration will be specific to your use case.

_This code is not specific to this package_

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// ...

This method gets the next chunk of data from the data source
Future<List<Post>> fetchPosts(int? cursor, int limit) async {
  final startIndex = cursor ?? 0;

  final response = await httpClient.get(
      Uri.https(
      'jsonplaceholder.typicode.com',
      '/posts',
      <String, String>{'_start': '$startIndex', '_limit': '$limit'},
      ),
  );

  if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.map((dynamic json) {
      final map = json as Map<String, dynamic>;
      return Post.fromJson(map);
      }).toList();
  }

  throw Exception('error fetching posts');
}
```

##### Widget Code

```dart
class PostsList extends StatelessWidget {
  const PostsList({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostBloc>();

    return PaginatedBuilder<Post, int>(
      // * Required when using `ListView.builder` Widget or new items won't
      //   show up
      rebuildListWhenChunkIsCached: true,
      // Required arguments
      listBuilder: (initialItemCount, paginatedItemBuilder) {
        return ListView.builder(
          itemBuilder: paginatedItemBuilder,
          itemCount: initialItemCount,
        );
      },
      itemBuilder: (context, data, [animation]) {
        return PostListItem(post: data.item);
      },
      dataChunker: bloc.fetchPosts, // Call the method from above
      // Optional arguments
      emptyWidget: const Center(child: Text('no posts')),
      cursorSelector: (Post post) => post.id,
    );
  }
}
```

#### Paginated Builder with Local Data Pagination

This example works well when you would like to have pagination from a design perspective, but have the entire list on hand.

Refer to the full example app under the `example` directory in the repo.

##### Local Data Pagination With Paginated Comparator

First we'll generate some data to show.

```dart
// As an example, we'll generate a bunch of fake posts
final allPosts =  List.generate(itemCount, (index) {
  final location = index + 1;
  // Post is defined as a model elsewhere (see example app in repo)
  return Post(
    id: location,
    title: 'post $location',
    body: 'post body',
  );
});

Future<List<Post>> _handleGetNext(Post? cursor, int limit) async {
  // If the cursor is null it means there was no previous chunk
  final isFirstRun = cursor == null;

  final data = isFirstRun
      // starting at the beginning of the list, get the maximum # of items
      ? widget.allPosts.take(limit)
      // otherwise, skip the ones we've already returned and get # of items
      : widget.allPosts
          .skipWhile((post) => post != cursor)
          .skip(1) // Start after the previous cursor
          .take(limit);

  // Adds artificial network delay to show item loading widget
  return Future.delayed(const Duration(seconds: 1), data.toList);
}
```

##### Widget Code

```dart
PaginatedComparator<Post, Post>(
  dataChunker: _handleGetNext, // Defined above!
  listBuilder: _listBuilder, // Defined below!
  itemBuilder: _itemBuilder, // Defined below!
  // Required when using a List wiget that doesn't allow
  // item insertion
  rebuildListWhenChunkIsCached: true,
)

///Controls what Widget is used to display the items being paginated through
Widget _listBuilder(
    int? initialItemCount,
    NullableIndexedWidgetBuilder paginatedItemBuilder,
  ) {
  return ListView.builder(
    itemCount: initialItemCount,
    itemBuilder: paginatedItemBuilder,
  );
}

/// Creates each item shown in the list
///
/// Called for each item in the list. This will most likely be called multiple
/// times for each item because the list we're using in the [_listBuilder]
/// will remove items as they're scrolled off the screen and recreate them as
/// they are scrolled back into view.
Widget _itemBuilder(
    BuildContext context,
    ItemComparator<Post> comparator, [
    Animation<double>? animation,
  ]) {
    // A local function used below to create columns for each item
    Widget toColumn(Post post, String position) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        key: Key('${post.id}_$position'),
        children: [
          Text(
            position,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge,
          )
        ],
      );
    }

    // Show a Card Widget (provided by Flutter) for each fake Post
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Comparator ${comparator.currentItem.index + 1}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                toColumn(comparator.previous, 'previous'),
                toColumn(comparator.current, 'current'),
                toColumn(comparator.next, 'next'),
              ],
            ),
          ],
        ),
      ),
    );
  }
```

## Arguments

### Required Args

#### listBuilder

The function used to generate the Widget containing all available items.

Commonly a `ListView.builder` Widget will be returned as you can directly replace `ListView`s required `itemBuilder` argument with the provided paginatedItemBuilder parameter.

> Warning: ensure you set the `rebuildListWhenChunkIsCached` to `true` if using a Widget that doesn't allow explicit insertion into the list. aka `ListView`

The `AnimatableIndexedWidgetBuilder` is the paginated item builder provided by this widget. Use it as a direct replacement for any regular or animated itemBuilder. This is the preferred implementation method since the entire list does not need to be rebuilt when a new chunk is received.

#### itemBuilder

The item builder is the same callback used with [ListView.builder] with one exception. Normally you receive an index, whereas with item builders you receive the item from the index.

##### Paginated Builder

With this, you receive your converted item at that index instead.

This item is retrieved from the in-memory cache located in the [PaginatedBuilderState.cachedItems] property of the State class.

##### Paginated Comparator

With this you receive converted items instead of an index. The converted items are the previous item, the current item, and the next item.

Items are retrieved from the in-memory cache located in the [PaginatedComparatorState.cachedItems] property of the State class.

#### dataChunker

Called to retrieve the next `n` number of items from your data source.

Use the provided `cursor` and `limit` to skip and get the next 'n' number of items. The cursor will be the identifier selected using the `cursorSelector` from the last time a chunk was retrieved.

If the `cursor` is `null`, this is the first time the method is being run for this data source.

The `limit` is the maximum amount of items the method expects to receive when being invoked.

> Warning: To avoid duplicate items, ensure you're getting the `limit` number of items AFTER the `cursor`.

### Optional Args

#### defaultThresholdPercent

The default value used to define how far the user can scroll before the
next chunk of data is retrieved.

#### listStartChangeStream

The stream listened to once the initial page load happens.

When items are added to this stream, they will be added to the beginning of the cache and `onItemReceived` will be called with a zero index.

#### onItemReceived

Invoked when data from a new chunk is received

The callback will be called for every item received in each chunk

#### onListRebuild

Invoked when the list rebuilds

The callback will be called for every rebuild of the list

#### chunkDataLimit

Used to limit the amount of data returned with each chunk

Whether to enable print statements or not

#### enablePrintStatements

Normally set to use `kIsDebug` so logs are printed while you're working, but not in production. This value can be set explicitly.

#### rebuildListWhenStreamHasChanges

Whether to recreate the the Widget provided in the `listBuilder` after a change comes through on the `listStartChangeStream`.

#### rebuildListWhenChunkIsCached

Whether to recreate the Widget provided in the `listBuilder` when items from a new chunk is added to the in-memory cache

By default, the list created by the `listBuilder` is only ever built once on initialization. Every time the list is re-built, all items need to be recreated using the item builder. Therefore, it is recommended to use a list that allows you to add in the items as they come in through the `onItemReceived` callback.

However, when using a standard `ListView`, there is no mechanism to insert items into the list without rebuilding the entire list. Because of this, you can set this value to `true` and the list will re-initialize with all of the cached items retrieved so far.

It's recommended to use a `AnimatedList` to insert and removes items from the state using a `GlobalKey` or the static `of` method (see AnimatedList's doc comments for details).

#### shouldShowItemLoader

Whether to replace the last item in the list with a loading Widget when a new chunk is being retrieved.

Defauls to `true`

#### cursorSelector

Used to select the value to passed into the `dataChunker` the next time it's called.

The cursor will come from the last item in the data returned by the `dataChunker`. The cursor should be used to skip any records previously retrieved before getting the next `n` records.

_`n` being the number of records specified by the limit provided to the `dataChunker` callback._
