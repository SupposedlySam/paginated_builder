import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:chunk/chunk.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_infinite_list/posts/posts.dart';
import 'package:http/http.dart' as http;

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Cubit<PostState> {
  PostBloc({required this.httpClient}) : super(const PostState());

  final http.Client httpClient;

  Future<List<Post>> fetchPosts(int? cursor, int limit) async {
    assert(limit > 0, "The limit should be greater than 0");

    final startIndex = cursor ?? 0;

    final response = await Future.delayed(
      Duration(seconds: 1),
      () => httpClient.get(
        Uri.https(
          'jsonplaceholder.typicode.com',
          '/posts',
          <String, String>{'_start': '$startIndex', '_limit': '$limit'},
        ),
      ),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.whereType<Map<String, dynamic>>().map((dynamic json) {
        return Post.fromJson(json);
      }).toList();
    }

    throw Exception('error fetching posts');
  }
}
