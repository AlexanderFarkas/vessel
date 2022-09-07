import 'package:honeycomb/honeycomb.dart';
import 'package:test/test.dart';

class SimpleCubit {
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

class DependentFamilyCubit {
  final FamilyCubit cubit;

  DependentFamilyCubit(this.cubit);

  @override
  String toString() {
    return "MyFamilyCubit($hashCode) -> cubit: $cubit";
  }
}


class DisposableCubit {
  final void Function() dispose;

  DisposableCubit(this.dispose);
}


final cubitProvider = Provider((ref) => SimpleCubit());
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
    final cubit1 = container.read(cubitProvider);
    final cubit2 = container.read(cubitProvider);

    expect(cubit1, equals(cubit2));
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
        familyProvider.overrideWith((param) => mockFamilyCubitProvider),
      ],
    );

    final cubit1 = mockedContainer.read(familyProvider(1));
    final cubit2 = mockedContainer.read(familyProvider(2));

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

        provider = Provider((read) => DependentFamilyCubit(read(familyProvider(3))));

        final mockedCubit1 = mockedContainer.read(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.read(provider).cubit;
        expect(mockedContainer.isPresent(familyProvider(3)), isTrue);
        expect(mockedContainer.isPresent(provider), isFalse);
        expect(container.isPresent(familyProvider(3)), isTrue);
        expect(container.isPresent(provider), isTrue);
        expect(mockedCubit1.number, isNot(equals(mockedCubit2.number)));
      });

      test("remains overridden inside child container with dependencies", () {
        final mockedContainer = Container(
          parent: container,
          overrides: overrides,
        );

        provider = Provider(
          (read) => DependentFamilyCubit(read(familyProvider(3))),
          dependencies: [familyProvider],
        );

        final mockedCubit1 = mockedContainer.read(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.read(provider).cubit;
        expect(mockedContainer.isPresent(familyProvider(3)), isTrue);
        expect(mockedContainer.isPresent(provider), isTrue);
        expect(container.isPresent(familyProvider(3)), isFalse);
        expect(container.isPresent(provider), isFalse);

        expect(mockedCubit1.number, equals(mockedCubit2.number));
      });

      test("remains overridden inside root container", () {
        final mockedContainer = Container(
          overrides: overrides,
        );
        final mockedCubit1 = mockedContainer.read(familyProvider(3));
        expect(mockedCubit1.number, equals(32));

        final mockedCubit2 = mockedContainer.read(provider).cubit;
        expect(mockedContainer.isPresent(familyProvider(3)), isTrue);
        expect(mockedContainer.isPresent(provider), isTrue);
        expect(container.isPresent(familyProvider(3)), isFalse);
        expect(container.isPresent(provider), isFalse);
        expect(mockedCubit1.number, equals(mockedCubit2.number));
      });
    },
  );

  group("Dispose", () {
    test("Simple", () {
      var calledOnce = false;
      final disposable = Provider<DisposableCubit>(
        (_) => DisposableCubit(() => calledOnce = true),
        dispose: (cubit) => cubit.dispose(),
      );

      container.read(disposable);
      expect(container.isPresent(disposable), isTrue);
      expect(calledOnce, isFalse);

      container.dispose();
      expect(calledOnce, isTrue);
    });
  });
}
