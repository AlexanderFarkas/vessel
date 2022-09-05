class Container implements Ref {
  final Container? parent;
  final List<OverrideBase> overrides;

  late final Map<Identifier, dynamic> _providables;
  late final Map<Identifier, OverrideBase> _overrides;

  Container({this.parent, this.overrides = const []}) {
    refresh();
  }

  void refresh() {
    _providables = {};
    _overrides = {for (final o in overrides) o.origin._identifier: o};
  }

  @override
  T read<T>(Provider<T> provider) {
    final identifier = provider._identifier;
    final overrideIdentifier = provider._createdBy._identifier;
    if (_providables.containsKey(identifier)) {
      return _providables[identifier];
    } else if (_overrides.containsKey(overrideIdentifier)) {
      return _providables[identifier] =
          _overrides[overrideIdentifier]!._performOverride(provider).create(this);
    } else if (parent != null) {
      return parent!.read(provider);
    } else {
      return _providables[identifier] = provider.create(this);
    }
  }
}

typedef ProviderCreate<T> = T Function(Ref ref);

abstract class Ref {
  T read<T>(Provider<T> provider);
}

abstract class OverrideBase<T> {
  Identifiable get origin;
  Provider<T> _performOverride(covariant Provider<T> provider);
}

class _Override<K extends Provider<T>, T> extends OverrideBase<T> {
  @override
  final Identifiable origin;
  final Provider<T> Function(K provider) performOverride;

  _Override({required this.origin, required this.performOverride});

  @override
  Provider<T> _performOverride(K provider) => performOverride(provider);
}

class ProviderOverride<T> extends OverrideBase<T> {
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

class ProviderFactoryOverride<T, K> extends OverrideBase<T> {
  @override
  final Identifiable origin;
  final Provider<T> Function(K param) _override;

  ProviderFactoryOverride(
    this.origin,
    this._override,
  );

  @override
  Provider<T> _performOverride(_FactoryProvider<T, K> provider) {
    return _override(provider._param);
  }
}

typedef Identifier = String;

abstract class Identifiable {
  Identifier get _identifier;
}

abstract class _Node<T> {
  Identifiable get _createdBy;
}

class Provider<T> extends OverrideBase<T> implements _Node, Identifiable {
  final T Function(Ref ref) create;

  Provider(this.create);

  static ProviderFactory<T, K> factory<T, K>(ProviderCreateFactory<T, K> create) {
    return ProviderFactory(create);
  }

  @override
  Identifiable get _createdBy => this;

  @override
  Identifier get _identifier => identityHashCode(this).toString();

  @override
  Provider<T> _performOverride(covariant Provider<T> provider) {
    return this;
  }

  OverrideBase<T> overrideWithProvider(Provider<T> Function() override) {
    return _Override<Provider<T>, T>(
      origin: this,
      performOverride: (provider) => override(),
    );
  }

  @override
  Identifiable get origin => this;
}

class _FactoryProvider<T, K> extends Provider<T> implements _Node {
  final K _param;

  @override
  final Identifiable _createdBy;

  @override
  Identifier get _identifier => "${identityHashCode(_createdBy)}/${_param.hashCode}";

  _FactoryProvider(this._createdBy, super.create, this._param);
}

typedef ProviderCreateFactory<T, K> = T Function(Ref ref, K param);

class ProviderFactory<T, K> extends OverrideBase<T> implements Identifiable {
  final ProviderCreateFactory<T, K> _create;

  ProviderFactory(this._create);

  Provider<T> call(K param) {
    return _FactoryProvider(this, (ref) => _create(ref, param), param);
  }

  OverrideBase<T> overrideWithProvider(Provider<T> Function(K param) override) {
    return _Override<_FactoryProvider<T, K>, T>(
      origin: this,
      performOverride: (provider) => override(provider._param),
    );
  }

  @override
  Identifier get _identifier => identityHashCode(this).toString();

  @override
  Provider<T> _performOverride(covariant Provider<T> provider) {
    return provider;
  }

  @override
  Identifiable get origin => this;
}
