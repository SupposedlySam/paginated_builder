import 'package:equatable/equatable.dart';

class Post extends Equatable {
  const Post({required this.id, required this.title, required this.body});

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String,
        body = json['body'] as String;

  final int id;
  final String title;
  final String body;

  @override
  List<Object> get props => [id, title, body];
}
