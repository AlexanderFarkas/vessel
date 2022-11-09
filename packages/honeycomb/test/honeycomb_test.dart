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
final familyProvider =
    Provider.factory<FamilyCubit, int>((ref, number) => FamilyCubit(number));

void main() {
  late ProviderContainer container;
  late ProviderContainer childWithScoped;
  late ProviderContainer childWithoutScoped;

  setUp(() {
    container = ProviderContainer();

    childWithoutScoped = ProviderContainer(
      overrides: [],
      parent: container,
    );

    childWithScoped = ProviderContainer(
      overrides: [cubitProvider.scope(), familyProvider.scope()],
      parent: container,
    );
  });

  group(
    "Always same",
    () {
      test("Single", () {
        final cubit1 = container.read(cubitProvider);
        final cubit2 = container.read(cubitProvider);

        expect(cubit1, equals(cubit2));
      });
      test("Family", () {
        final cubit1 = container.read(familyProvider(1));
        final cubit2 = container.read(familyProvider(1));

        expect(cubit1, equals(cubit2));
      });
    },
  );

  group('Parent relationship', () {
    group('Without scopes', () {
      test(
        "Single",
        () {
          final cubit1 = container.read(cubitProvider);
          final cubit2 = childWithoutScoped.read(cubitProvider);

          expect(cubit1, equals(cubit2));
        },
      );
      test(
        "Family",
        () {
          final cubit1 = container.read(familyProvider(3));
          final cubit2 = childWithoutScoped.read(familyProvider(3));

          expect(cubit1, equals(cubit2));
        },
      );
    });

    group('With scopes', () {
      test("Single", () {
        final cubit1 = container.read(cubitProvider);
        final cubit2 = childWithScoped.read(cubitProvider);

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Family", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = childWithScoped.read(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));
      });
    });

    group("Family values", () {
      test("Not equal", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = container.read(familyProvider(4));

        expect(cubit1, isNot(equals(cubit2)));
      });

      test("Same in parent after scope in child", () {
        final cubit1 = container.read(familyProvider(3));
        final cubit2 = childWithScoped.read(familyProvider(3));

        expect(cubit1, isNot(equals(cubit2)));

        final cubit3 = container.read(familyProvider(3));
        expect(cubit3, equals(cubit1));
      });
    });
  });

  test("Override with mock", () {
    final mockFamilyCubitProvider = Provider((ref) => FamilyCubit(32));
    final mockedContainer = ProviderContainer(
      overrides: [
        familyProvider.overrideWith((param) => mockFamilyCubitProvider),
      ],
    );

    final cubit1 = mockedContainer.read(familyProvider(1));
    final cubit2 = mockedContainer.read(familyProvider(2));

    expect(cubit1, isNot(equals(cubit2)));
    expect(cubit1.number, equals(cubit2.number));
  });

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

  test("Scoping", () {
    final provider1 = Provider((_) => Counter(0));
    final provider2 = Provider((read) => Counter(read(provider1).count + 1));
    final provider3 = Provider((read) => Counter(read(provider2).count + 3));

    final container = ProviderContainer();
    final containerChild = ProviderContainer(
      overrides: [provider2.scope()],
      parent: container,
    );
    final containerChild2 =
        ProviderContainer(overrides: [], parent: containerChild);
    final containerChild3 = ProviderContainer(
        overrides: [provider2.scope()], parent: containerChild2);

    // now provider3 also scoped inside containerChild
    final instance3 = containerChild2.read(provider3);
    final rootInstance3 = container.read(provider3);

    expect(identical(instance3, rootInstance3), isFalse); // false
    expect(containerChild.isPresent(provider3), isTrue);
    expect(containerChild.isPresent(provider2), isTrue);
    expect(containerChild2.isPresent(provider3), isFalse);
    expect(containerChild2.isPresent(provider2), isFalse);
    expect(containerChild3.isPresent(provider2), isFalse);
    expect(containerChild3.isPresent(provider2), isFalse);
    expect(container.isPresent(provider3), isTrue);
    expect(container.isPresent(provider2), isTrue);

    containerChild3.read(provider3);
    expect(containerChild3.isPresent(provider3), isTrue);

    final instance1 = containerChild.read(provider1);
    final rootInstance1 = container.read(provider1);

    // provider1 doesn't have scoped dependencies, so it doesn't become scoped.
    expect(identical(instance1, rootInstance1), isTrue); // true
  });

  group(
    "https://github.com/rrousselGit/riverpod/issues/1629",
    () {
      group("single values", () {
        test("original comment", () {
          final provider1 = Provider((_) => Counter(1));
          final provider2 =
              Provider((read) => Counter(read(provider1).count + 1));
          final provider3 =
              Provider((read) => Counter(read(provider2).count + 1));

          final root = ProviderContainer();
          final child1 = ProviderContainer(overrides: [], parent: root);
          final child2 = ProviderContainer(
              overrides: [provider2.scope(), provider3.scope()],
              parent: child1);
          final child3 =
              ProviderContainer(overrides: [provider1.scope()], parent: child2);

          child3.read(provider3);
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(0));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(0));
        });

        test("tweaked", () {
          final provider1 = Provider((_) => Counter(1));
          final provider2 =
              Provider((read) => Counter(read(provider1).count + 1));
          final provider3 =
              Provider((read) => Counter(read(provider2).count + 1));

          final root = ProviderContainer();
          final child1 = ProviderContainer(overrides: [], parent: root);
          final child2 =
              ProviderContainer(overrides: [provider2.scope()], parent: child1);
          final child3 =
              ProviderContainer(overrides: [provider1.scope()], parent: child2);

          child3.read(provider3);
          child3.read(provider2);
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(0));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(0));
        });
      });
      group("factory values", () {
        final provider1 = Provider.factory((_, int count) => Counter(1));
        final provider2 = Provider.factory(
            (read, int count) => Counter(read(provider1(count)).count + 1));
        final provider3 = Provider.factory(
            (read, int count) => Counter(read(provider2(count)).count + 1));

        test("original comment", () {
          final root = ProviderContainer();
          final child1 = ProviderContainer(overrides: [], parent: root);
          final child2 = ProviderContainer(
              overrides: [provider2.scope(), provider3.scope()],
              parent: child1);
          final child3 =
              ProviderContainer(overrides: [provider1.scope()], parent: child2);

          child3.read(provider3(3));
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(0));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(0));

          child2.read(provider3(2));
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(2));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(1));
        });

        test("tweaked", () {
          final root = ProviderContainer();
          final child1 = ProviderContainer(overrides: [], parent: root);
          final child2 =
              ProviderContainer(overrides: [provider2.scope()], parent: child1);
          final child3 =
              ProviderContainer(overrides: [provider1.scope()], parent: child2);

          child3.read(provider3(3));
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(0));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(0));

          child2.read(provider3(2));
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(2));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(1));

          child2.read(provider2(2));
          child3.read(provider3(3));
          child3.read(provider1(3));
          child1.read(provider1(2));
          child2.read(provider1(2));
          expect(child3.providablesLength(), equals(3));
          expect(child2.providablesLength(), equals(2));
          expect(child1.providablesLength(), equals(0));
          expect(root.providablesLength(), equals(1));
        });
      });
    },
  );
  group("Overrides", () {
    test("Primitives", () {
      final healthProvider = Provider((_) => 100);
      final bossHealthProvider = Provider((_) => 50);

      final root = ProviderContainer();
      final bossRoom = ProviderContainer(
        overrides: [healthProvider.overrideWith(bossHealthProvider)],
      );

      final generalHealth = root.read(healthProvider);
      expect(generalHealth, equals(100));

      final bossHealth = bossRoom.read(healthProvider);
      expect(bossHealth, equals(50));
    });

    test("Factory", () {
      final healthProvider = Provider.factory((read, int health) => health);
      final bossHealthProvider = Provider((_) => 50);

      final root = ProviderContainer();
      final bossRoom = ProviderContainer(
        overrides: [
          healthProvider.overrideWith((health) => bossHealthProvider)
        ],
      );

      final generalHealth = root.read(healthProvider(100));
      expect(generalHealth, equals(100));

      final bossHealth = bossRoom.read(healthProvider(200));
      expect(bossHealth, equals(50));
    });
  });
}

class Counter {
  final int count;
  Counter(this.count);
}
