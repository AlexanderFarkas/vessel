import 'package:comparison/common.dart';
import 'package:comparison/register.dart';
import 'package:honeycomb/honeycomb.dart';

final mockRepositoryProvider = Provider((read) => MockUserRepository());

class MockUserRepository implements UserRepository {
  @override
  String usernameById(int userId) {
    return "Mock";
  }
}

void overrideHoneycomb() {
  final rootContainer = ProviderContainer();
  final childContainer = ProviderContainer(
      parent: rootContainer,
      overrides: [userRepositoryProvider.overrideWith(mockRepositoryProvider)]);

  final vm = childContainer.read(userViewModelProvider(1));
  vm.sayHello(); // Hello, Mock

  final repository = childContainer.read(userRepositoryProvider);
  print(repository.usernameById(1)); // Mock

  /// It's useful in UI, since not all parts of your app 
  /// need access to the overriden/scoped version of the provider.
  /// 
  /// Providing overriden version to a subtree is pretty usefull in Flutter, 
  /// rest of the app will still be using the root one
  final rootVm = rootContainer.read(userViewModelProvider(1));
  rootVm.sayHello(); // Hello, Barry
}

void overrideGetIt() {
  getIt.pushNewScope(init: (getIt) {
    getIt.registerSingleton<UserRepository>(MockUserRepository());
  });

  final vm = getIt.get<UserViewModel>(param1: 1);
  vm.sayHello(); // Hello, Mock

  final repository = getIt.get<UserRepository>();
  print(repository.usernameById(1)); // Mock

  /// As far as I know, 
  /// it's not possible to use root scope without popping the current.
}
