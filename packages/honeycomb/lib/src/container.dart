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
  HashMap<ProviderFactory, FactoryOverride> get _factoryOverrides;
  HashMap<ProviderBase, ProviderOverride> get _providerOverrides;
  Map<ProviderBase, dynamic> get _providables;
  _RootContainer get _rootContainer;

  late final List<void Function()> _onDispose = [];

  _CreateResult<T> _create<T>(ProviderBase<T> provider) => _circularDependencyCheck(
        lock: provider,
        () {
          final directDependencies = HashSet<MaybeScoped>();

          final actualProvider = _findOverride(provider);

          // Пройти по всем зависимостям - и только слайсить их??
          final value = actualProvider.create(<T>(ProviderBase<T> dependency) {
            if (dependency is FactoryProvider<T, dynamic>) {
              directDependencies.add(dependency.factory);
            } else if (dependency is Provider<T>) {
              directDependencies.add(dependency);
            }
            return read(dependency);
          });

          final result = _CreateResult(
            value: value,
            origin: provider,
            dependencies: directDependencies,
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

    _rootContainer.directDependencies[key] ??= result.dependencies;
  }

  HashSet<MaybeScoped>? _getDirectDependencies<T>(ProviderBase<T> provider) {
    final key = _getDependencyKey(provider);
    return _rootContainer.directDependencies[key];
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

  @visibleForTesting
  int providablesLength() {
    return _providables.length;
  }

  bool isScoped<T>(ProviderBase<T> provider);
}

class _CreateResult<T> {
  final T value;
  final ProviderBase<T> origin;
  final ProviderBase<T> actualProvider;
  final HashSet<MaybeScoped> dependencies;

  _CreateResult({
    required this.value,
    required this.origin,
    required this.actualProvider,
    required this.dependencies,
  });
}

class _RootContainer extends ProviderContainer {
  @override
  final _providables = <ProviderBase, dynamic>{};
  final HashMap<MaybeScoped, HashSet<MaybeScoped>> directDependencies = HashMap();

  @override
  late final HashMap<ProviderFactory, FactoryOverride> _factoryOverrides;

  @override
  late final HashMap<ProviderBase, ProviderOverride> _providerOverrides;

  _RootContainer({List<Override> overrides = const []}) : super._() {
    final HashMap<ProviderFactory, FactoryOverride> factoryOverrides = HashMap();
    final HashMap<ProviderBase, ProviderOverride> providerOverrides = HashMap();

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
  late final _RootContainer _rootContainer = this;

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
  final HashSet<MaybeScoped> scoped;

  @override
  final _providables = <ProviderBase, dynamic>{};

  _ScopedContainer(
    List<MaybeScoped> scoped, {
    required this.parent,
  })  : scoped = HashSet.from(scoped),
        // assert(
        //   scoped.isNotEmpty,
        //   "There is no practical usage for scoped container with empty dependencies",
        // ),
        super._();

  @override
  late final HashMap<ProviderFactory, FactoryOverride> _factoryOverrides = parent._factoryOverrides;

  @override
  late final HashMap<ProviderBase, ProviderOverride> _providerOverrides = parent._providerOverrides;

  @override
  T read<T>(ProviderBase<T> provider) {
    if (_providables.containsKey(provider)) {
      return _providables[provider];
    }

    final dependencies = _getDirectDependencies(provider);
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

  final cachedIsScoped = {};

  @override
  bool isScoped<T>(ProviderBase<T> provider) {
    return _isScoped(_getDependencyKey(provider));
  }

  bool _isScoped<T>(MaybeScoped dependency) {
    return cachedIsScoped[dependency] ??= scoped.contains(dependency) ||
        _rootContainer.directDependencies[dependency]!.any(_isScoped);
  }
}
