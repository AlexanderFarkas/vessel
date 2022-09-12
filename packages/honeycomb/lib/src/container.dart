part of '../honeycomb.dart';

ProviderBase? _circularDependencySentinel;

abstract class ProviderContainer {
  factory ProviderContainer({List<Override> overrides}) = _RootContainer;

  factory ProviderContainer.root({
    List<Override> overrides,
  }) = _RootContainer;

  factory ProviderContainer.scoped(
    List<MaybeScoped> scoped, {
    required ProviderContainer parent,
  }) = _ScopedContainer;

  ProviderContainer._();

  /// Public api
  T read<T>(ProviderBase<T> provider);

  void dispose() {
    for (final dispose in _onDispose) {
      dispose();
    }
  }

  /// Implementation
  Map<ProviderFactory, FactoryOverride> get _factoryOverrides;
  Map<ProviderBase, ProviderOverride> get _providerOverrides;
  Map<ProviderBase, dynamic> get _providables;
  _RootContainer get _rootContainer;

  late final List<void Function()> _onDispose = [];

  _CreateResult<T> _create<T>(ProviderBase<T> provider) => _circularDependencyCheck(
        lock: provider,
        () {
          final Set<MaybeScoped> dependencies = {};

          final actualProvider = _findOverride(provider);
          final value = actualProvider.create(<T>(ProviderBase<T> dependency) {
            if (dependency is FactoryProvider<T, dynamic>) {
              dependencies.add(dependency.factory);
            } else if (dependency is Provider<T>) {
              dependencies.add(dependency);
            }

            final value = read(_findOverride(dependency));
            dependencies.addAll(_getDependencies(dependency)!);

            return value;
          });

          final result = _CreateResult(
            value: value,
            origin: provider,
            dependencies: dependencies,
            actualProvider: actualProvider,
          );

          _setDependencies(result);

          return result;
        },
      );

  ProviderBase<T> _findOverride<T>(ProviderBase<T> provider) {
    ProviderBase<dynamic>? overridden = provider is FactoryProvider<T, dynamic>
        ? _factoryOverrides[provider.factory]?.getOverride(provider)
        : _providerOverrides[provider]?._override;

    return (overridden as ProviderBase<T>?) ?? provider;
  }

  _CreateResult<T> _circularDependencyCheck<T>(_CreateResult<T> Function() create,
      {required ProviderBase<T> lock}) {
    if (_circularDependencySentinel == lock) {
      throw CircularDependencyException("There is a circular dependency on $lock");
    }

    _circularDependencySentinel ??= lock;

    try {
      return create();
    } finally {
      _circularDependencySentinel = null;
    }
  }

  T _setProvidableFromResult<T>(_CreateResult<T> result) {
    final dispose = result.actualProvider.dispose;
    if (dispose != null) {
      _onDispose.add(() => dispose.call(result.value));
    }
    return _providables[result.origin] = result.value;
  }

  void _setDependencies<T>(_CreateResult<T> result) {
    final origin = result.origin;

    late final MaybeScoped key;
    if (origin is FactoryProvider<T, dynamic>) {
      key = origin.factory;
    } else if (origin is Provider<T>) {
      key = origin;
    }

    _rootContainer.dependencies[key] ??= result.dependencies;
  }

  Set<MaybeScoped>? _getDependencies<T>(ProviderBase<T> provider) {
    final key = _getDependencyKey(provider);
    return _rootContainer.dependencies[key];
  }

  MaybeScoped _getDependencyKey<T>(ProviderBase<T> origin) {
    late final MaybeScoped key;
    if (origin is FactoryProvider<T, dynamic>) {
      key = origin.factory;
    } else if (origin is Provider<T>) {
      key = origin;
    }
    return key;
  }

  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return _providables.containsKey(provider);
  }

  bool isScoped<T>(ProviderBase<T> provider);
}

class _CreateResult<T> {
  final T value;
  final ProviderBase<T> origin;
  final ProviderBase<T> actualProvider;
  final Set<MaybeScoped> dependencies;

  _CreateResult({
    required this.value,
    required this.origin,
    required this.actualProvider,
    required this.dependencies,
  });
}

class _RootContainer extends ProviderContainer {
  @override
  final Map<ProviderBase, dynamic> _providables = {};
  final Map<MaybeScoped, Set<MaybeScoped>> dependencies = {};

  @override
  late final Map<ProviderFactory, FactoryOverride> _factoryOverrides;

  @override
  late final Map<ProviderBase, ProviderOverride> _providerOverrides;

  _RootContainer({List<Override> overrides = const []}) : super._() {
    final Map<ProviderFactory, FactoryOverride> factoryOverrides = {};
    final Map<ProviderBase, ProviderOverride> providerOverrides = {};

    for (final override in overrides) {
      if (override is ProviderOverride) {
        providerOverrides[override._origin] = override;
      } else if (override is FactoryOverride) {
        factoryOverrides[override._origin] = override;
      } else {
        throw UnimplementedError("Not implemented override: $override");
      }
    }
    _factoryOverrides = factoryOverrides;
    _providerOverrides = providerOverrides;
  }

  @override
  _RootContainer get _rootContainer => this;

  @override
  T read<T>(ProviderBase<T> provider) {
    if (_providables.containsKey(provider)) {
      return _providables[provider];
    } else {
      return _setProvidableFromResult(_create<T>(provider));
    }
  }

  @override
  bool isScoped<T>(ProviderBase<T> provider) {
    // Root container implicitly 'scopes' all providers
    return true;
  }
}

class _ScopedContainer extends ProviderContainer {
  final ProviderContainer parent;
  final Set<MaybeScoped> scoped;

  @override
  final Map<ProviderBase, dynamic> _providables = {};

  _ScopedContainer(
    List<MaybeScoped> scoped, {
    required this.parent,
  })  : scoped = scoped.toSet(),
        // assert(
        //   scoped.isNotEmpty,
        //   "There is no practical usage for scoped container with empty dependencies",
        // ),
        super._();

  @override
  Map<ProviderFactory, FactoryOverride> get _factoryOverrides => parent._factoryOverrides;

  @override
  Map<ProviderBase, ProviderOverride> get _providerOverrides => parent._providerOverrides;

  @override
  T read<T>(ProviderBase<T> provider) {
    if (_providables.containsKey(provider)) {
      return _providables[provider];
    }

    final dependencies = _getDependencies(provider);
    if (dependencies == null) {
      final result = _create(provider);

      ProviderContainer container = this;
      while (container is! _RootContainer) {
        if (container.isScoped(result.origin)) {
          return container._setProvidableFromResult(result);
        }
        container = (container as _ScopedContainer).parent;
      }
    } else if (isScoped(provider)) {
      return _providables[provider] = _create(provider).value;
    }

    return parent.read(provider);
  }

  @override
  _RootContainer get _rootContainer => parent._rootContainer;

  @override
  bool isScoped<T>(ProviderBase<T> provider) {
    if (scoped.contains(_getDependencyKey(provider))) {
      return true;
    }

    return scoped.any(_getDependencies(provider)!.contains);
  }
}
