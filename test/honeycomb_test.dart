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
final familyProvider = Provider.factory((ref, int number) => FamilyCubit(number));

void main() {
  late Container container;
  late Container childWithOverrides;
  late Container childWithoutOverrides;

  setUp(() {
    container = Container();
    childWithoutOverrides = Container(parent: container);
    childWithOverrides = Container(parent: container, overrides: [cubitProvider, familyProvider]);
  });

  group('Parent relationship', () {
    group('Without overrides', () {
      test(
        "Single",
        () {
          final cubit1 = container.read(cubitProvider);
          final cubit2 = childWithoutOverrides.read(cubitProvider);

          expect(cubit1, equals(cubit2));
        },
      );
      test(
        "Family",
        () {
          final cubit1 = container.read(familyProvider(3));
          final cubit2 = childWithoutOverrides.read(familyProvider(3));

          expect(cubit1, equals(cubit2));
        },
      );
    });

    group('With overrides', () {
      test("Single", () {
        final cubit1 = container.read(cubitProvider);
        final cubit2 = childWithOverrides.read(cubitProvider);

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Family", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = childWithOverrides.read(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));
      });
    });

    group("Family values", () {
      test("Not equal", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = container.read(familyProvider(4));

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Same in parent after override in child", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = childWithOverrides.read(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));

        final cubit3 = container.read(familyProvider(3));
        expect(cubit3, equals(cubit1));
      });
    });
  });

  test("Override with mock", () {
    final mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
    final mockedContainer = Container(
      overrides: [
        familyProvider.overrideWithProvider((param) => mockFamilyCubitProvider),
      ],
    );

    final cubit1 = mockedContainer.read(familyProvider(1));
    final cubit2 = mockedContainer.read(familyProvider(2));

    expect(cubit1, isNot(equals(cubit2)));
    expect(cubit1.number, equals(cubit2.number));
  });
}
