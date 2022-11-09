import 'package:comparison/common.dart';
import 'package:comparison/register.dart';
import 'package:honeycomb/honeycomb.dart';

void readHoneycomb() {
  final container = ProviderContainer();

  /// fails to compile, since "random_uuid" is not subtype of int
  // final vm = container.read(userViewModelProvider("random_uuid"));

  /// you cannot forget to register userViewModelProvider,
  /// since it's "registered" at compile-time
  final vm = container.read(userViewModelProvider(1));
  vm.sayHello(); // Hello, Barry
}

void readGetIt() {
  /// If you forger to register UserViewModel, it will fail at runtime
  // getIt.get<UserViewModel>(param1: 1);

  /// You may fail to pass param1, error at runtime
  // getIt.get<UserViewModel>();

  /// You may pass the wrong type, error at runtime
  /// getIt.get<UserViewModel>(param1: "random_uuid");

  final vm = getIt.get<UserViewModel>(param1: 1);
  vm.sayHello(); // Hello, Barry
}
