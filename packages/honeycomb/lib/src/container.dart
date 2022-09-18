part of 'internal_api.dart';

ProviderBase? _circularDependencySentinel;

abstract class ProviderContainer {
  factory ProviderContainer({List<Override> overrides}) = RootProviderContainer;

  factory ProviderContainer.root({
    List<Override> overrides,
  }) = RootProviderContainer;

  factory ProviderContainer.scoped(
    List<MaybeScoped> scoped, {
    required ProviderContainer parent,
  }) =>
      ScopedProviderContainer(
        scoped,
        parent: parent,
        cachedIsScoped: {},
        providables: {},
      );

  @internal
  factory ProviderContainer.shared(
    List<MaybeScoped> scoped, {
    required ProviderContainer parent,
    required Map<ProviderBase, dynamic> providables,
    required Map<MaybeScoped, bool> cachedIsScoped,
  }) =>
      ScopedProviderContainer(
        scoped,
        parent: parent,
        cachedIsScoped: cachedIsScoped,
        providables: providables,
      );

  ProviderContainer._();

  /// Public api
  T read<T>(ProviderBase<T> provider);

  void disposeProvidables() {
    for (final dispose in onDispose) {
      dispose();
    }
  }

  /// Implementation
  HashMap<ProviderFactory, FactoryOverride> get _factoryOverrides;
  HashMap<ProviderBase, ProviderOverride> get _providerOverrides;

  @protected
  Map<ProviderBase, dynamic> get providables;

  @protected
  RootProviderContainer get rootContainer;

  @internal
  late final List<void Function()> onDispose = [];

  ProviderCreationResult<T> _create<T>(ProviderBase<T> provider) => _circularDependencyCheck(
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

          final result = ProviderCreationResult(
            value: value,
            origin: provider,
            dependencies: directDependencies,
            actualProvider: actualProvider,
          );

          setDependencies(result);

          return result;
        },
      );

  ProviderBase<T> _findOverride<T>(ProviderBase<T> provider) {
    ProviderBase<dynamic>? overridden = provider is FactoryProvider<T, dynamic>
        ? _factoryOverrides[provider.factory]?.getOverride(provider)
        : _providerOverrides[provider]?._override;

    return (overridden as ProviderBase<T>?) ?? provider;
  }

  ProviderCreationResult<T> _circularDependencyCheck<T>(ProviderCreationResult<T> Function() create,
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

  @protected
  @internal
  T setProvidableFromResult<T>(ProviderCreationResult<T> result) {
    final dispose = result.actualProvider.dispose;
    if (dispose != null) {
      onDispose.add(() => dispose.call(result.value));
    }
    return providables[result.origin] = result.value;
  }

  @protected
  @internal
  void setDependencies<T>(ProviderCreationResult<T> result) {
    final origin = result.origin;

    late final MaybeScoped key;
    if (origin is FactoryProvider<T, dynamic>) {
      key = origin.factory;
    } else if (origin is Provider<T>) {
      key = origin;
    }

    rootContainer.directDependencies[key] ??= result.dependencies;
  }

  @protected
  @internal
  HashSet<MaybeScoped>? getDirectDependencies<T>(ProviderBase<T> provider) {
    final key = getDependencyKey(provider);
    return rootContainer.directDependencies[key];
  }

  @protected
  @internal
  MaybeScoped getDependencyKey<T>(ProviderBase<T> origin) {
    late final MaybeScoped key;
    if (origin is FactoryProvider<T, dynamic>) {
      key = origin.factory;
    } else if (origin is Provider<T>) {
      key = origin;
    }
    return key;
  }

  @protected
  @internal
  bool isScoped<T>(ProviderBase<T> provider);

  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return providables.containsKey(provider);
  }

  @visibleForTesting
  int providablesLength() {
    return providables.length;
  }
}

@internal
class ProviderCreationResult<T> {
  final T value;
  final ProviderBase<T> origin;
  final ProviderBase<T> actualProvider;
  final HashSet<MaybeScoped> dependencies;

  ProviderCreationResult({
    required this.value,
    required this.origin,
    required this.actualProvider,
    required this.dependencies,
  });
}

class RootProviderContainer extends ProviderContainer {
  @override
  final providables = <ProviderBase, dynamic>{};
  final HashMap<MaybeScoped, HashSet<MaybeScoped>> directDependencies = HashMap();

  @override
  late final HashMap<ProviderFactory, FactoryOverride> _factoryOverrides;

  @override
  late final HashMap<ProviderBase, ProviderOverride> _providerOverrides;

  RootProviderContainer({List<Override> overrides = const []}) : super._() {
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
  late final RootProviderContainer rootContainer = this;

  @override
  T read<T>(ProviderBase<T> provider) {
    if (providables.containsKey(provider)) {
      return providables[provider];
    } else {
      return setProvidableFromResult(_create<T>(provider));
    }
  }

  @override
  bool isScoped<T>(ProviderBase<T> provider) {
    // Root container implicitly 'scopes' all providers
    return true;
  }
}

class ScopedProviderContainer extends ProviderContainer {
  final ProviderContainer parent;
  final HashSet<MaybeScoped> scoped;

  @override
  final Map<ProviderBase, dynamic> providables;

  final Map<MaybeScoped, bool> cachedIsScoped;

  ScopedProviderContainer(
    List<MaybeScoped> scoped, {
    required this.providables,
    required this.cachedIsScoped,
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
    if (providables.containsKey(provider)) {
      return providables[provider];
    }

    final dependencies = getDirectDependencies(provider);
    if (dependencies == null) {
      final result = _create(provider);

      ProviderContainer container = this;
      while (container is! RootProviderContainer) {
        if (container.isScoped(result.origin)) {
          return container.setProvidableFromResult(result);
        }
        container = (container as ScopedProviderContainer).parent;
      }
    } else if (isScoped(provider)) {
      return providables[provider] = _create(provider).value;
    }

    return parent.read(provider);
  }

  @override
  RootProviderContainer get rootContainer => parent.rootContainer;

  @override
  bool isScoped<T>(ProviderBase<T> provider) {
    return _isScoped(getDependencyKey(provider));
  }

  bool _isScoped<T>(MaybeScoped dependency) {
    return cachedIsScoped[dependency] ??=
        scoped.contains(dependency) || rootContainer.directDependencies[dependency]!.any(_isScoped);
  }
}

