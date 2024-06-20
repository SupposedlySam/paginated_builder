import 'package:equatable/equatable.dart';
import 'package:paginated_builder/paginated_builder.dart';

final class Post extends PaginatedSnapshot<PostData> {
  const Post({
    required super.data,
  }) : super(state: SnapshotState.added);

  const Post.deleted({
    required super.data,
  }) : super(state: SnapshotState.deleted);

  Post.updated({
    required super.data,
  }) : super(
          state: SnapshotState.updated,
          uniqueIdFinder: (PostData data) => data.id,
        );

  int get id => data.id;
  String get title => data.title;
  String get body => data.body;
}

final class ExceptionOnUpdatePost extends PaginatedSnapshot<PostData> {
  const ExceptionOnUpdatePost({
    required super.data,
  }) : super(state: SnapshotState.added);

  const ExceptionOnUpdatePost.updated({
    required super.data,
  }) : super(
          state: SnapshotState.updated,
          // Setting this to null so it throws for testing purposes
          uniqueIdFinder: null,
        );
}

class PostData extends Equatable {
  const PostData({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  PostData copyWith({
    int? id,
    String? title,
    String? body,
  }) {
    return PostData(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  @override
  List<Object> get props => [id, title, body];
}
