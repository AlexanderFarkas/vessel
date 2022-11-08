import 'package:comparison/common.dart';
import 'package:get_it/get_it.dart';
import 'package:honeycomb/honeycomb.dart';

final userRepositoryProvider = Provider((read) => UserRepository());
final userViewModelProvider = Provider.factory(
  (read, int userId) => UserViewModel(
    userId,
    read(userRepositoryProvider),
  ),
);

final getIt = GetIt.asNewInstance();
void getItSetup() {
  getIt.registerSingleton(UserRepository());
  getIt.registerFactoryParam<UserViewModel, int, dynamic>(
    (param1, param2) => UserViewModel(
      param1,
      getIt.get<UserRepository>(),
    ),
  );
}
