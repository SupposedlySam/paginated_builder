import 'package:bloc/bloc.dart';
import 'package:example/paginated_builder/view/post_model.dart';

class BasicPaginatedBuilderCubit extends Cubit<List<Post>> {
  BasicPaginatedBuilderCubit(this.itemCount) : super([]);

  final int itemCount;

  void generateItems() {
    emit(
      List.generate(itemCount, (index) {
        final location = index + 1;
        return Post(
          id: location,
          title: 'post $location',
          body: 'post body',
        );
      }),
    );
  }
}
