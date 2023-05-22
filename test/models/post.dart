import 'package:equatable/equatable.dart';
import 'package:paginated_builder/paginated_builder.dart';

final class Post extends PaginatedSnapshot<PostData> {
  const Post({
    required super.data,
  }) : super(state: SnapshotState.stable);

  const Post.deleted({
    required super.data,
  }) : super(state: SnapshotState.deleted);

  int get id => data.id;
  String get title => data.title;
  String get body => data.body;
}

class PostData extends Equatable {
  const PostData({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  @override
  List<Object> get props => [id, title, body];
}
