class Container implements Ref {
  final Container? parent;
  final Map<Identifier, dynamic> providables = {};
  late final Map<Identifier, Override> overrides;

  Container({this.parent, List<Override> overrides = const []}) {
    this.overrides = {for (final o in overrides) o.origin.identifier: o};
  }

  @override
  T read<T>(Provider<T> provider) {
    final identifier = provider.createdBy.identifier;

    if (providables.containsKey(identifier)) {
      return providables[identifier];
    } else if (overrides.containsKey(identifier)) {
      return providables[identifier] ??=
          overrides[identifier]!._performOverride(provider).create(this);
    } else if (parent != null) {
      return parent!.read(provider);
    } else {
      return providables[identifier] = provider.create(this);
    }
  }
}

typedef ProviderCreate<T> = T Function(Ref ref);

abstract class Ref {
  T read<T>(Provider<T> t);
}

abstract class Override<T> {
  Identifiable get origin;
  Provider<T> _performOverride(covariant Provider<T> provider);
}

class ProviderOverride<T> extends Override<T> {
  @override
  final Identifiable origin;

  final ProviderCreate<T> _override;

  ProviderOverride(
    this.origin,
    this._override,
  );

  @override
  Provider<T> _performOverride(Provider<T> provider) {
    return Provider(_override);
  }
}

class ProviderFactoryOverride<T, K> extends Override<T> {
  @override
  final Identifiable origin;
  final Provider<T> Function(K param) _override;

  ProviderFactoryOverride(
    this.origin,
    this._override,
  );

  @override
  Provider<T> _performOverride(_FactoryProvider<T, K> provider) {
    return _override(provider.param);
  }
}

typedef Identifier = int;
mixin Identifiable {
  Identifier get identifier => identityHashCode(this);
}

abstract class _Node<T> {
  Identifiable get createdBy;
}

class Provider<T> with Identifiable implements _Node {
  final T Function(Ref ref) create;

  Provider(this.create);

  @override
  Identifiable get createdBy => this;
}

class _FactoryProvider<T, K> extends Provider<T> implements _Node {
  final K param;

  @override
  final Identifiable createdBy;

  _FactoryProvider(this.createdBy, super.create, this.param);
}

class ProviderFactory<T, K> with Identifiable {
  final T Function(Ref ref, K param) create;

  ProviderFactory(this.create);

  Provider<T> call(K param) {
    return Provider((ref) => create(ref, param));
  }
}
