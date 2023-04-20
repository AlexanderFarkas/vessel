import 'package:vessel/vessel.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

abstract class Repository {
  final CommonDataSource common;

  Repository(this.common);
}

class CommonDataSource {}

class HttpSpecificDataSource {}

class HttpRepositoryImpl extends Repository {
  final HttpSpecificDataSource http;
  HttpRepositoryImpl(super.common, this.http);
}

class DatabaseSpecificDataSource {}

class DatabaseRepositoryImpl extends Repository {
  final DatabaseSpecificDataSource db;
  DatabaseRepositoryImpl(super.common, this.db);
}

class Cubit {
  final Repository repository;

  Cubit(this.repository);
}

class HiveDatabaseSpecificDataSource extends DatabaseSpecificDataSource {}

void main() {
  final commonDataSourceProvider = Provider((_) => CommonDataSource());
  final httpDataSourceProvider = Provider((_) => HttpSpecificDataSource());
  final dbDataSourceProvider = Provider((_) => DatabaseSpecificDataSource());
  final repositoryProvider = Provider<Repository>((read) => null as Repository);
  final httpRepositoryProvider = Provider(
    (read) => HttpRepositoryImpl(
      read(commonDataSourceProvider),
      read(httpDataSourceProvider),
    ),
  );
  final dbRepositoryProvider = Provider(
    (read) => DatabaseRepositoryImpl(
      read(commonDataSourceProvider),
      read(dbDataSourceProvider),
    ),
  );

  final cubitProvider = Provider((read) => Cubit(read(repositoryProvider)));

  test("New dependency from override is correcly placed in root", () {
    final root = ProviderContainer(
        overrides: [repositoryProvider.overrideWith(httpRepositoryProvider)]);

    root.read(repositoryProvider);
    expect(root.providables.containsKey(httpDataSourceProvider), isTrue);

    final child = ProviderContainer(
        parent: root,
        overrides: [repositoryProvider.overrideWith(dbRepositoryProvider)]);

    child.read(repositoryProvider);
    expect(root.providables.containsKey(dbDataSourceProvider), isTrue);

    expect(root.providables.length, equals(4));
    expect(child.providables.length, equals(1));
  });

  test("Complex", () {
    final root = ProviderContainer(
      overrides: [repositoryProvider.overrideWith(httpRepositoryProvider)],
    );

    final hiveDataSourceProvider = Provider<DatabaseSpecificDataSource>(
        (read) => HiveDatabaseSpecificDataSource());

    root.read(cubitProvider);

    final child = ProviderContainer(
      parent: root,
      overrides: [dbDataSourceProvider.overrideWith(hiveDataSourceProvider)],
    );

    final child2 = ProviderContainer(
      parent: child,
      overrides: [repositoryProvider.overrideWith(dbRepositoryProvider)],
    );

    final cubit = child2.read(cubitProvider);
    expect(cubit.repository, isA<DatabaseRepositoryImpl>());
    expect((cubit.repository as DatabaseRepositoryImpl).db,
        isA<HiveDatabaseSpecificDataSource>());

    expect(root.providables.length, equals(4));
    expect(child.providables.length, equals(1));
    expect(child2.providables.length, equals(2));
  });
}
