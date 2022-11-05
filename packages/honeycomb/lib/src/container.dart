part of 'internal_api.dart';

ProviderBase? _circularDependencySentinel;

class ProviderContainer {
  final ProviderContainer? parent;
  final int depth;

  /// Implementation
  final dependencies = HashMap<MaybeScoped, DependencyNode>();
  final providables = HashMap<ProviderBase, dynamic>();

  final Set<Override> overrides;
  late final HashMap<ProviderFactoryBase, FactoryOverride> _factoryOverrides;
  late final HashMap<SingleProviderBase, ProviderOverride> _providerOverrides;

  @internal
  late final List<void Function()> onDispose = [];

  ProviderContainer({
    this.parent,
    List<Override> overrides = const [],
  })  : overrides = overrides.toSet(),
        depth = parent != null ? parent.depth + 1 : 0 {
    final HashMap<ProviderFactoryBase, FactoryOverride> factoryOverrides = HashMap();
    final HashMap<SingleProviderBase, ProviderOverride> providerOverrides = HashMap();

    for (final override in overrides) {
      if (override is ProviderOverride) {
        providerOverrides[override._origin] = override;
      } else if (override is FactoryOverride) {
        factoryOverrides[override._origin] = override;
      }
    }
    _factoryOverrides = factoryOverrides;
    _providerOverrides = providerOverrides;
  }

  final cachedShouldOverride = <ProviderBase>{};

  void dispose() {
    for (final dispose in onDispose) {
      dispose();
    }
  }

  final readCache = <ProviderBase, dynamic>{};
  T read<T>(ProviderBase<T> provider) {
    return readCache[provider] ??= _read(provider).value;
  }

  ReadResult<T> _read<T>(ProviderBase<T> provider) {
    if (providables.containsKey(provider)) {
      return ReadResult(
        dependencies[provider.toScopable()]!,
        providables[provider],
      );
    }

    ProviderContainer? host = this;
    while (host != null) {
      final providables = host.providables[provider];
      if (providables != null) {
        break;
      }
      host = host.parent;
    }

    if (host == null) {
      final result = _create(provider);
      ProviderContainer candidate = this;

      while (candidate.parent != null) {
        if (candidate.isScoped(result.dependencyNode)) {
          break;
        }
        candidate = candidate.parent!;
      }

      return candidate.mountProvider(result);
    } else {
      ProviderContainer candidate = this;
      final node = host.dependencies[provider.toScopable()]!;
      while (candidate != host) {
        if (candidate.isScoped(node)) {
          break;
        }

        candidate = candidate.parent!;
      }

      if (candidate != host) {
        final result = _create(provider);
        return candidate.mountProvider(result);
      } else {
        return host._read(provider);
      }
    }
  }

  bool isScoped(DependencyNode node) {
    final scopable = node.scopable;
    final isScopedDirectly = scopable is ProviderFactoryBase
        ? _factoryOverrides.keys.contains(scopable)
        : _providerOverrides.keys.contains(scopable);

    return isScopedDirectly || node.dependencies.any(isScoped);
  }

  CreateResult<T> _create<T>(ProviderBase<T> provider) => _circularDependencyCheck(
        lock: provider,
        () {
          final dependencies = HashSet<DependencyNode>();

          final override = _findOverride<T>(provider);
          final overrideOrProvider = override ?? provider;

          final value = overrideOrProvider.create(<T>(ProviderBase<T> dependency) {
            final result = _read(dependency);
            dependencies.add(result.node);
            return result.value;
          });

          return CreateResult(
            origin: provider,
            override: override,
            value: value,
            dependencyNode: DependencyNode(
              scopable: provider.toScopable(),
              dependencies: dependencies,
            ),
          );
        },
      );

  ReadResult<T> mountProvider<T>(CreateResult<T> result) {
    this
      ..dependencies[result.dependencyNode.scopable] = result.dependencyNode
      ..providables[result.origin] = result.value;

    final dispose = result.overrideOrProvider.dispose;
    if (dispose != null) {
      onDispose.add(() => dispose.call(result.value));
    }

    return ReadResult(result.dependencyNode, result.value);
  }

  ProviderBase<T>? _findOverride<T>(ProviderBase<T> provider) {
    ProviderBase<dynamic>? overridden;
    ProviderContainer container = this;

    while (overridden == null) {
      overridden = provider is FactoryProviderBase<T, dynamic>
          ? container._factoryOverrides[provider.factory]?.getOverride(provider)
          : container._providerOverrides[provider]?._override;

      final parent = container.parent;
      if (parent == null) {
        break;
      }
      container = parent;
    }

    return overridden as ProviderBase<T>?;
  }

  CreateResult<T> _circularDependencyCheck<T>(
    CreateResult<T> Function() create, {
    required ProviderBase<T> lock,
  }) {
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

  final cachedIsScoped = HashMap<Override, bool>();

  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return providables.containsKey(provider);
  }

  @visibleForTesting
  int providablesLength() => providables.length;
}

class DependencyNode {
  final Set<DependencyNode> dependencies;
  final MaybeScoped scopable;

  DependencyNode({
    required this.dependencies,
    required this.scopable,
  });

  @override
  int get hashCode => scopable.hashCode;

  @override
  operator ==(Object? other) => other is DependencyNode && other.scopable == scopable;
}

class ReadResult<T> {
  final DependencyNode node;
  final T value;

  ReadResult(this.node, this.value);
}

class CreateResult<T> {
  final ProviderBase<T> origin;
  final ProviderBase<T>? override;
  final T value;
  final DependencyNode dependencyNode;

  ProviderBase<T> get overrideOrProvider => override ?? origin;

  CreateResult({
    required this.origin,
    required this.override,
    required this.value,
    required this.dependencyNode,
  });
}

class FindOverrideResult<T> {
  final ProviderContainer container;
  final ProviderBase<T>? override;

  FindOverrideResult({
    required this.container,
    required this.override,
  });
}

class DirectDependencyMap {
  final _map = HashMap<MaybeScoped, Set<MaybeScoped>>();

  void operator []=(ProviderBase provider, Set<MaybeScoped> dependencies) {
    _map[scopableFromProvider(provider)] = dependencies;
  }

  Set<MaybeScoped>? operator [](ProviderBase provider) {
    return _map[scopableFromProvider(provider)];
  }

  Set<MaybeScoped>? get(Override key) {
    return _map[key];
  }
}

MaybeScoped scopableFromProvider<T>(ProviderBase<T> origin) {
  late final MaybeScoped key;
  if (origin is FactoryProviderBase<T, dynamic>) {
    key = origin.factory;
  } else if (origin is SingleProviderBase<T>) {
    key = origin;
  } else {
    throw UnsupportedError("message"); // fixme
  }
  return key;
}

class CircularDependencyException implements Exception {
  final String message;
  CircularDependencyException(this.message);

  @override
  String toString() {
    return "CircularDependencyException: $message";
  }
}
