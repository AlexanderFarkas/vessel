import 'package:meta/meta.dart';

class Container {
  final Container? parent;
  final Map<Identifier, ProviderWithState> _providables = {};

  final Map<ProviderFactory, FactoryOverride> _factoryOverrides = {};
  final Map<ProviderBase, ProviderOverride> _providerOverrides = {};

  Container({
    this.parent,
    List<Override> overrides = const [],
  }) {
    for (final override in overrides) {
      _setOverride(override);
    }
  }

  T read<T>(ProviderBase<T> provider) {
    final identifier = provider.identifier;

    if (_providables.containsKey(identifier)) {
      return _providables[identifier]!.state;
    }

    ProviderWithState<T> create(ProviderBase<T> provider) => ProviderWithState(
          provider,
          provider.create(read),
        );

    final overriddenProvider = _findOverride(provider);
    if (overriddenProvider != null) {
      return _set(identifier, create(overriddenProvider));
    }

    return parent != null ? parent!.read(provider) : _set(identifier, create(provider));
  }

  void dispose() {
    for (final providerWithState in _providables.values) {
      providerWithState.dispose();
    }
  }

  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return _providables.containsKey(provider.identifier);
  }

  ProviderBase<T>? _findOverride<T>(ProviderBase<T> provider) {
    ProviderBase<dynamic>? overridden = provider is FactoryProvider<T, dynamic>
        ? _factoryOverrides[provider.factory]?.getOverride(provider)
        : _providerOverrides[provider]?._override;

    if (overridden == null && _shouldScopeProvider(provider)) {
      overridden = _setOverride(provider);
    }

    return overridden as ProviderBase<T>?;
  }

  bool _shouldScopeProvider<T>(ProviderBase<T> provider) {
    return provider.allTransitiveDependencies.any(
      (dep) => _factoryOverrides.containsKey(dep) || _providerOverrides.containsKey(dep),
    );
  }

  T _setOverride<T extends Override>(T override) {
    if (override is ProviderOverride) {
      return _providerOverrides[override._origin] = override;
    } else if (override is FactoryOverride) {
      return _factoryOverrides[override._origin] = override;
    } else {
      throw UnimplementedError("Not implemented override: $override");
    }
  }

  T _set<T>(Identifier key, ProviderWithState<T> value) {
    return (_providables[key] = value).state;
  }
}

class ProviderWithState<TState> {
  final ProviderBase<TState> provider;
  final TState state;

  ProviderWithState(this.provider, this.state);

  void dispose() {
    return provider.dispose?.call(state);
  }
}

typedef Identifier = String;

abstract class Override {}

class ProviderOverride<T> extends Override {
  final ProviderBase<T> _origin;
  final ProviderBase<T> _override;

  ProviderOverride({required ProviderBase<T> origin, required ProviderBase<T> override})
      : _origin = origin,
        _override = override;
}

typedef FactoryOverrideFn<TState, TArg> = ProviderBase<TState> Function(TArg);

abstract class FactoryOverride<TState, TArg> extends Override {
  final ProviderFactory<TState, TArg> _origin;
  final FactoryOverrideFn<TState, TArg> _override;

  FactoryOverride({
    required ProviderFactory<TState, TArg> origin,
    required FactoryOverrideFn<TState, TArg> override,
  })  : _origin = origin,
        _override = override;

  ProviderBase<TState> getOverride(FactoryProvider<TState, TArg> provider);
}

class _FactoryOverride<TState, TArg> extends FactoryOverride<TState, TArg>
    with FactoryOverrideMixin<TState, TArg> {
  _FactoryOverride({required super.origin, required super.override});
}

mixin FactoryOverrideMixin<TState, TArg> on FactoryOverride<TState, TArg> {
  @override
  ProviderBase<TState> getOverride(FactoryProvider<TState, TArg> provider) {
    return _override(provider.param);
  }
}

typedef Dispose<T> = void Function(T state);
typedef ReadProvider = T Function<T>(ProviderBase<T> provider);
typedef ProviderCreate<T> = T Function(ReadProvider read);
typedef ProviderFactoryCreate<T, K> = T Function(ReadProvider read, K param);

abstract class ProviderOrFactory<T> {
  final Dispose<T>? dispose;
  final List<ProviderOrFactory> dependencies;
  late final List<ProviderOrFactory> allTransitiveDependencies =
      _allTransitiveDependencies(dependencies);

  ProviderOrFactory({required this.dispose, required List<ProviderOrFactory>? dependencies})
      : dependencies = dependencies ?? const [];

  static List<ProviderOrFactory> _allTransitiveDependencies(List<ProviderOrFactory> dependencies) {
    final deps = <ProviderOrFactory>{};
    for (final dep in dependencies) {
      deps.add(dep);
      deps.addAll(dep.allTransitiveDependencies);
    }

    return deps.toList(growable: false);
  }
}

abstract class ProviderBase<T> extends ProviderOrFactory<T> implements ProviderOverride<T> {
  final ProviderCreate<T> create;

  @override
  ProviderBase<T> get _origin => this;

  @override
  ProviderBase<T> get _override => this;

  Identifier get identifier;

  ProviderBase(
    this.create, {
    required Dispose<T>? dispose,
    required List<ProviderOrFactory>? dependencies,
  }) : super(
          dispose: dispose,
          dependencies: dependencies,
        );
}

class Provider<T> extends ProviderBase<T> {
  Provider(
    ProviderCreate<T> create, {
    Dispose<T>? dispose,
    List<ProviderOrFactory>? dependencies,
  }) : super(create, dispose: dispose, dependencies: dependencies);

  ProviderOverride<T> overrideWith(Provider<T> provider) {
    return ProviderOverride(
      origin: this,
      override: provider,
    );
  }

  @override
  Identifier get identifier => identityHashCode(this).toString();
}

abstract class ProviderFactoryBase<TState, TArg> extends ProviderOrFactory<TState>
    implements FactoryOverride<TState, TArg> {
  ProviderFactoryBase({required super.dispose, required super.dependencies});
}

class ProviderFactory<T, K> extends ProviderFactoryBase<T, K> with FactoryOverrideMixin<T, K> {
  final ProviderFactoryCreate<T, K> create;
  ProviderFactory(
    this.create, {
    super.dispose,
    super.dependencies,
  });

  @override
  ProviderFactory<T, K> get _origin => this;

  @override
  FactoryOverrideFn<T, K> get _override => call;

  ProviderBase<T> call(K param) {
    return FactoryProvider<T, K>(
      (get) => create(get, param),
      factory: this,
      dependencies: dependencies,
      dispose: dispose,
      param: param,
    );
  }

  FactoryOverride<T, K> overrideWith(ProviderBase<T> Function(K) providerBuilder) {
    return _FactoryOverride(
      origin: this,
      override: providerBuilder,
    );
  }
}

class FactoryProvider<T, K> extends ProviderBase<T> {
  final K param;
  final ProviderFactory<T, K> factory;
  FactoryProvider(
    super.create, {
    required this.factory,
    required super.dispose,
    required super.dependencies,
    required this.param,
  });

  @override
  String get identifier => "${identityHashCode(factory)}/${param.hashCode}";
}

///->Container
/// >providers:[Identifiable:Provider.value]
/// >overrides:[Identifiable:OverrideBase]
///->Provider
///-->
///
///
///