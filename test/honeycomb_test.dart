import 'package:honeycomb/honeycomb.dart';
import 'package:test/test.dart';

class MyCubit {
  @override
  String toString() {
    return "MyCubit($hashCode)";
  }
}

class FamilyCubit {
  final int number;

  FamilyCubit(this.number);

  @override
  String toString() {
    return "FamilyCubit($hashCode) -> number: $number";
  }
}

class MyFamilyCubit {
  final FamilyCubit cubit;

  MyFamilyCubit(this.cubit);

  @override
  String toString() {
    return "MyFamilyCubit($hashCode) -> cubit: $cubit";
  }
}

final cubitProvider = Provider((ref) => MyCubit());
final familyProvider = ProviderFactory((ref, int number) => FamilyCubit(number));

void main() {
  late Container container;
  late Container childWithOverrides;
  late Container childWithoutOverrides;

  setUp(() {
    container = Container();
    childWithoutOverrides = Container(parent: container);
    childWithOverrides = Container(parent: container, overrides: [cubitProvider, familyProvider]);
  });

  test("Always same", () {
    final cubit1 = container.get(cubitProvider);
    final cubit2 = container.get(cubitProvider);

    expect(cubit1, equals(cubit2));
  });

  group('Parent relationship', () {
    group('Without overrides', () {
      test(
        "Single",
        () {
          final cubit1 = container.get(cubitProvider);
          final cubit2 = childWithoutOverrides.get(cubitProvider);

          expect(cubit1, equals(cubit2));
        },
      );
      test(
        "Family",
        () {
          final cubit1 = container.get(familyProvider(3));
          final cubit2 = childWithoutOverrides.get(familyProvider(3));

          expect(cubit1, equals(cubit2));
        },
      );
    });

    group('With overrides', () {
      test("Single", () {
        final cubit1 = container.get(cubitProvider);
        final cubit2 = childWithOverrides.get(cubitProvider);

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Family", () {
        final cubit1 = container.get(familyProvider(3));
        final cubit2 = childWithOverrides.get(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));
      });
    });

    group("Family values", () {
      test("Not equal", () {
        final cubit1 = container.get(familyProvider(3));
        final cubit2 = container.get(familyProvider(4));

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Same in parent after override in child", () {
        final cubit1 = container.get(familyProvider(3));
        final cubit2 = childWithOverrides.get(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));

        final cubit3 = container.get(familyProvider(3));
        expect(cubit3, equals(cubit1));
      });
    });
  });

  test("Override with mock", () {
    final mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
    final mockedContainer = Container(
      overrides: [
        familyProvider.overrideWith((param) => mockFamilyCubitProvider),
      ],
    );

    final cubit1 = mockedContainer.get(familyProvider(1));
    final cubit2 = mockedContainer.get(familyProvider(2));

    expect(cubit1, isNot(equals(cubit2)));
    expect(cubit1.number, equals(cubit2.number));
  });

  group(
    "Transitive dependency",
    () {
      var mockFamilyCubitProvider, provider, overrides;
      setUp(() {
        mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
        overrides = [
          familyProvider.overrideWith((param) => mockFamilyCubitProvider),
        ];
      });

      test("Lost inside child container without dependencies", () {
        final mockedContainer = Container(
          parent: container,
          overrides: overrides,
        );

        provider = Provider((get) => MyFamilyCubit(get(familyProvider(3))));

        final mockedCubit1 = mockedContainer.get(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.get(provider).cubit;
        expect(mockedCubit1.number, isNot(equals(mockedCubit2.number)));
      });

      test("remains overridden inside child container with dependencies", () {
        final mockedContainer = Container(
          parent: container,
          overrides: overrides,
        );

        provider = Provider(
          (get) => MyFamilyCubit(get(familyProvider(3))),
          dependencies: [familyProvider],
        );

        final mockedCubit1 = mockedContainer.get(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.get(provider).cubit;
        expect(mockedCubit1.number, equals(mockedCubit2.number));
      });

      test("remains overridden inside root container", () {
        final mockedContainer = Container(
          overrides: overrides,
        );
        final mockedCubit1 = mockedContainer.get(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.get(provider).cubit;
        expect(mockedCubit1.number, equals(mockedCubit2.number));
      });
    },
  );
}
