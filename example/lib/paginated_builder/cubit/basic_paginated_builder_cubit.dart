import 'package:bloc/bloc.dart';
import 'package:example/paginated_builder/view/post_model.dart';

class BasicPaginatedBuilderCubit extends Cubit<List<Post>> {
  BasicPaginatedBuilderCubit()
      : super(
          List.generate(100, (index) {
            final location = index + 1;
            return Post(
              id: location,
              title: 'post $location',
              body: 'post body',
            );
          }),
        );
}
