// import 'package:riverpod/riverpod.dart';

// import '../test/honeycomb_test.dart';

// final familyProvider = Provider.family((ref, int number) => FamilyCubit(number));
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:honeycomb/honeycomb.dart';

final familyProvider = Provider.family<int, int>((ref, value) {
  return value;
});

final anotherFamilyProvider = Provider.family<int, int>((ref, value) {
  return value * 2;
});

void main(List<String> args) {
  ProviderContainer(overrides: [
    familyProvider.overrideWithProvider((argument) => anotherFamilyProvider(argument)),
  ]);
  // final mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
  // final mockedContainer = ProviderContainer(
  //   overrides: [
  //     familyProvider.overrideWithProvider((param) => mockFamilyCubitProvider),
  //   ],
  // );

  // final cubit1 = mockedContainer.read(familyProvider(1));
  // final cubit2 = mockedContainer.read(familyProvider(2));

  // print(cubit1 == cubit2);
  // print(cubit1.number == cubit2.number);
}
