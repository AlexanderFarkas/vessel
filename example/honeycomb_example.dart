

import 'package:riverpod/riverpod.dart';

import '../test/honeycomb_test.dart';

final familyProvider = Provider.family((ref, int number) => FamilyCubit(number));
void main(List<String> args) {
  final mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
  final mockedContainer = ProviderContainer(
    overrides: [
      familyProvider.overrideWithProvider((param) => mockFamilyCubitProvider),
    ],
  );

  final cubit1 = mockedContainer.read(familyProvider(1));
  final cubit2 = mockedContainer.read(familyProvider(2));

  print(cubit1 == cubit2);
  print(cubit1.number == cubit2.number);
}
