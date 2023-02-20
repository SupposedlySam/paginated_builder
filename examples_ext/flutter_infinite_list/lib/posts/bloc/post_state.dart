part of 'post_bloc.dart';

enum PostStatus { initial, success, failure }

class PostState extends Equatable {
  const PostState({
    this.chunk = const Chunk(limit: 20),
    this.status = PostStatus.initial,
    this.posts = const <Post>[],
    this.hasReachedMax = false,
  });

  final Chunk<Post, int> chunk;
  final PostStatus status;
  final List<Post> posts;
  final bool hasReachedMax;

  PostState copyWith({
    Chunk<Post, int>? chunk,
    PostStatus? status,
    List<Post>? posts,
    bool? hasReachedMax,
  }) {
    return PostState(
      chunk: chunk ?? this.chunk,
      status: status ?? this.status,
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  String toString() {
    final readableChunk =
        '''Chunk(dataLength: ${chunk.data.length}, cursor: ${chunk.cursor}, limit: ${chunk.limit}, status: ${chunk.status.name})''';
    return '''PostState { chunk: $readableChunk, status: $status, hasReachedMax: $hasReachedMax, posts: ${posts.length} }''';
  }

  @override
  List<Object> get props => [chunk, status, posts, hasReachedMax];
}
