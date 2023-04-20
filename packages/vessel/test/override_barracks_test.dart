import 'package:vessel/vessel.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

enum Weapon {
  sword,
  spear,
}

class Warrior {
  final Weapon weapon;

  Warrior(this.weapon);
}

class Castle {
  final Warrior owner;

  Castle(this.owner);
}

class Wizard {}

void main() {
  test("Direct", () {
    final warriorProvider =
        Provider.factory((read, Weapon weapon) => Warrior(weapon));
    final wizzardProvider = Provider((read) => Wizard());

    final root = ProviderContainer();
    final warrior1 = root.read(warriorProvider(Weapon.sword));
    final warrior2 = root.read(warriorProvider(Weapon.sword));
    final wizzard1 = root.read(wizzardProvider);

    expect(warrior1, equals(warrior2));

    final onlySpears = ProviderContainer(
      parent: root,
      overrides: [
        warriorProvider.overrideWith((weapon) => warriorProvider(Weapon.spear))
      ],
    );

    final warrior3 = onlySpears.read(warriorProvider(Weapon.sword));
    final warrior4 = onlySpears.read(warriorProvider(Weapon.sword));
    final wizzard2 = onlySpears.read(wizzardProvider);
    expect(warrior3.weapon, equals(Weapon.spear));
    expect(warrior3, equals(warrior4));

    // we expect it to be different, since we provided
    final warrior5 = onlySpears.read(warriorProvider(Weapon.spear));
    expect(warrior4, isNot(equals(warrior5)));

    final onlySwords = ProviderContainer(
      parent: onlySpears,
      overrides: [
        warriorProvider.overrideWith((weapon) => warriorProvider(Weapon.sword))
      ],
    );

    final warrior6 = onlySwords.read(warriorProvider(Weapon.spear));
    final warrior7 = onlySwords.read(warriorProvider(Weapon.spear));
    final wizzard3 = onlySwords.read(wizzardProvider);
    expect(warrior6.weapon, equals(Weapon.sword));
    expect(warrior6, equals(warrior7));

    final warrior8 = onlySwords.read(warriorProvider(Weapon.sword));
    expect(warrior7, isNot(equals(warrior8)));

    final againNormalBarracks = ProviderContainer(
      parent: onlySwords,
      overrides: [
        warriorProvider.overrideWith((weapon) => warriorProvider(weapon))
      ],
    );

    final warrior9 = againNormalBarracks.read(warriorProvider(Weapon.spear));
    final warrior10 = againNormalBarracks.read(warriorProvider(Weapon.spear));
    final wizzard4 = againNormalBarracks.read(wizzardProvider);
    expect(warrior9.weapon, equals(Weapon.spear));
    expect(warrior9, equals(warrior10));

    final warrior11 = againNormalBarracks.read(warriorProvider(Weapon.sword));
    expect(warrior9, isNot(equals(warrior11)));
    expect(warrior9.weapon, isNot(equals(warrior11.weapon)));

    expect(
      wizzard1 == wizzard2 && //
          wizzard2 == wizzard3 &&
          wizzard3 == wizzard4 &&
          wizzard4 == wizzard1,
      isTrue,
    );

    expect(root.providables.length, equals(2));
    expect(
      [onlySwords, onlySpears, againNormalBarracks]
          .every((container) => container.providables.length == 2),
      isTrue,
    );
  });

  group("Transitive", () {
    final swordManProvider = Provider((_) => Warrior(Weapon.sword));
    final spearManProvider = Provider((_) => Warrior(Weapon.spear));
    final castleProvider = Provider((read) => Castle(read(swordManProvider)));

    late ProviderContainer root;
    late ProviderContainer child;
    setUp(() {
      root = ProviderContainer();
      child = ProviderContainer(
        parent: root,
        overrides: [
          swordManProvider.overrideWith(spearManProvider),
        ],
      );
    });

    test("child first", () {
      final castle = child.read(castleProvider);
      expect(castle.owner.weapon, equals(Weapon.spear));
      expect(root.providables.length, equals(0));
      expect(child.providables.length, equals(2));

      expect(root.read(castleProvider), isNot(equals(castle)));

      expect(root.providables.length, equals(2));
      expect(child.providables.length, equals(2));

      // we expect them to be different
      expect(child.read(spearManProvider),
          isNot(equals(child.read(swordManProvider))));
    });

    test("root first", () {
      final castle = root.read(castleProvider);
      expect(castle.owner.weapon, equals(Weapon.sword));
      expect(root.providables.length, equals(2));
      expect(child.providables.length, equals(0));

      expect(child.read(castleProvider), isNot(equals(castle)));

      expect(root.providables.length, equals(2));
      expect(child.providables.length, equals(2));
      // we expect them to be different
      expect(child.read(spearManProvider),
          isNot(equals(child.read(swordManProvider))));
    });
  });
}
