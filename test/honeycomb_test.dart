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
        expect(mockedContainer.isPresent(provider), isTrue);
        expect(container.isPresent(familyProvider(3)), isFalse);
        expect(container.isPresent(provider), isFalse);
        expect(mockedCubit1.number, equals(mockedCubit2.number));
      });

      test("remains overridden inside child container with dependencies", () {
        final mockedContainer = Container(
          parent: container,
          overrides: overrides,
        );

        provider = Provider(
          (read) => DependentFamilyCubit(read(familyProvider(3))),
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

  group("Integration test 1", () {
    final providerFactorySquared = ProviderFactory((read, int value) {
      return value * value;
    });

    final providerTripleThenSquared = ProviderFactory((read, int value) {
      return read(providerFactorySquared(value * 3));
    });

    final providerFactoryDoubled = ProviderFactory((read, int value) {
      return value * 2;
    });

    final provider5 = Provider((read) => 5);
    final provider4 = Provider(
      (read) {
        read(provider5);

        return 4;
      },
    );
    final provider2 = Provider(
      (read) {
        read(provider4);
        read(provider5);

        return read(providerFactoryDoubled(4));
      },
      debugName: "provider2",
    );
    final provider3 = Provider((read) {
      read(provider4);
      read(provider5);

      return read(providerFactorySquared(3));
    });
    final provider1 = Provider(
      (read) {
        read(provider2);
        read(provider3);

        return 1;
      },
    );

    final mockProvider2 = Provider((_) => 22);

    group(
      "Part 1",
      () {
        late Container container;
        late Container containerRank2;
        late Container containerRank3;
        late Container otherContainerRank3;

        setUp(() {
          container = Container();
          containerRank2 = Container(
            parent: container,
            overrides: [
              provider2.overrideWith(mockProvider2),
            ],
          );
          containerRank3 = Container(parent: containerRank2, overrides: [
            provider2,
          ]);
          otherContainerRank3 = Container(parent: containerRank2);
        });

        test("1", () {
          expect(container.read(provider2), equals(8));
          expect(containerRank2.read(provider2), equals(22));
          expect(containerRank3.read(provider2), equals(8));
          expect(otherContainerRank3.read(provider2), equals(22));

          expect(container.isPresent(provider2), isTrue);
          expect(containerRank2.isPresent(provider2), isTrue);
          expect(containerRank3.isPresent(provider2), isTrue);
          expect(otherContainerRank3.isPresent(provider2), isFalse);
        });
      },
    );
    group(
      "Part 2",
      () {
        final mockTripleThenSquared =
            ProviderFactory((read, int number) => read(providerFactoryDoubled(number * 3)));

        late Container container;
        late Container containerRank2;

        setUp(() {
          container = Container();
          containerRank2 = Container(
            parent: container,
            overrides: [
              providerTripleThenSquared.overrideWith(mockTripleThenSquared),
            ],
          );
        });

        test("1", () {
          expect(container.read(providerTripleThenSquared(3)), equals(81));
          expect(container.isPresent(providerTripleThenSquared(3)), isTrue);
          expect(containerRank2.isPresent(providerTripleThenSquared(3)), isFalse);

          expect(containerRank2.read(providerTripleThenSquared(3)), equals(18));
          expect(container.isPresent(providerTripleThenSquared(3)), isTrue);
          expect(containerRank2.isPresent(providerTripleThenSquared(3)), isTrue);
        });

        test("Reversed 1", () {
          expect(containerRank2.read(providerTripleThenSquared(3)), equals(18));
          expect(container.isPresent(providerTripleThenSquared(3)), isFalse);
          expect(containerRank2.isPresent(providerTripleThenSquared(3)), isTrue);

          expect(container.read(providerTripleThenSquared(3)), equals(81));
          expect(container.isPresent(providerTripleThenSquared(3)), isTrue);
          expect(containerRank2.isPresent(providerTripleThenSquared(3)), isTrue);
        });
      },
    );
    group(
      "Part 3",
      () {
        late Container container;
        late Container containerRank2;

        setUp(() {
          container = Container();
          containerRank2 = Container(parent: container);
        });

        test("1", () {
          final s5_1 = container.read(provider5);
          final s5_2 = containerRank2.read(provider5);
          expect(s5_1, equals(5));
          expect(s5_2, equals(5));
          expect(s5_1, equals(s5_2));

          expect(container.isPresent(provider5), isTrue);
          expect(containerRank2.isPresent(provider5), isFalse);
        });

        test("Reversed 1", () {
          final s5_2 = containerRank2.read(provider5);
          final s5_1 = container.read(provider5);
          expect(s5_1, equals(5));
          expect(s5_2, equals(5));
          expect(s5_1, equals(s5_2));

          expect(container.isPresent(provider5), isTrue);
          expect(containerRank2.isPresent(provider5), isFalse);
        });
      },
    );
  });

  group("Hirachy test", () {
    Container? c1, c2, c3, c4, c5;

    setUp(() {
      c1 = Container();
      c2 = Container(parent: c1);
      c3 = Container(parent: c2);
    });

    test("Single", () {
      final provider = Provider((_) => 1);
      final override = Provider((_) => 2);

      c4 = Container(parent: c3, overrides: [provider.overrideWith(override)]);
      c5 = Container(parent: c4);

      expect(c3!.read(provider), 1);
      expect(c1!.isPresent(provider), isTrue);
      expect([c2, c3, c4, c5].every((c) => !c!.isPresent(provider)), isTrue);

      expect(c5!.read(provider), 2);
      expect([c1, c4].every((c) => c!.isPresent(provider)), isTrue);
      expect(
        [
          c2,
          c3,
          c5,
        ].every((c) => !c!.isPresent(provider)),
        isTrue,
      );
    });

    test("Factory", () {
      final providerFactory = ProviderFactory<int, String>((_, value) => value.length);
      final providerFactoryOverride = ProviderFactory<int, String>((_, value) => value.length * 2);

      c4 = Container(
        parent: c3,
        overrides: [providerFactory.overrideWith(providerFactoryOverride)],
      );
      c5 = Container(parent: c4);

      expect(c3!.read(providerFactory("Hello")), 5);
      expect(c1!.isPresent(providerFactory("Hello")), isTrue);
      expect([c2, c3, c4, c5].every((c) => !c!.isPresent(providerFactory("Hello"))), isTrue);

      expect(c5!.read(providerFactory("Hello")), 10);
      expect([c1, c4].every((c) => c!.isPresent(providerFactory("Hello"))), isTrue);
      expect(
        [
          c2,
          c3,
          c5,
        ].every((c) => !c!.isPresent(providerFactory("Hello"))),
        isTrue,
      );
    });
  });
}
