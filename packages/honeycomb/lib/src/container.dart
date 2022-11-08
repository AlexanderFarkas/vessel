part of 'internal_api.dart';

ProviderBase? _circularDependencySentinel;

/// Container of providers' instances
/// It manages parent-child relationship between containers, overrides and scopes
///
/// {@template overrides}
/// [overrides] is a list of providers you're willing to scope/override
/// {@endtemplate}
/// {@template parent}
/// [parent] is a container, which will be explored in case [provider] either
/// cannot be found or isntantiated.
/// {@endtemplate}
class ProviderContainer {
  // ignore: public_member_api_docs
  ProviderContainer({
    this.parent,
    List<Override> overrides = const [],
  }) : overrides = overrides.toSet() {
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

  /// Reads [provider]'s value from container.
  /// If [provider]'s value hasn't been created, this function creates it and puts it in cache.
  T read<T>(ProviderBase<T> provider) {
    return _readCache[provider] ??= _read(provider).value;
  }

  /// Disposes all providers' values, calling [dispose] function of [ProviderOrFactory]
  /// If provider is overriden with another provider, latter [dispose] will be called.
  void dispose() {
    for (final dispose in onDispose) {
      dispose();
    }
  }

  /// {@macro parent}
  @visibleForTesting
  final ProviderContainer? parent;

  /// 1 to 1 mapping of [provider] and its dependencies
  /// if [provider] is present as key in [providables], it's guaranteed
  /// that it's [provider.toScopable] is present in [dependencies].
  @visibleForTesting
  final dependencies = HashMap<MaybeScoped, _DependencyNode>();

  /// Mapping of providers to their values
  /// key is **NOT* overridden member, so it's essentially the one consumer uses in [read] call.
  @visibleForTesting
  final providables = HashMap<ProviderBase, dynamic>();

  /// {@macro overrides}
  @visibleForTesting
  final Set<Override> overrides;
  late final HashMap<ProviderFactoryBase, FactoryOverride> _factoryOverrides;
  late final HashMap<SingleProviderBase, ProviderOverride> _providerOverrides;

  /// List of dispose functions.
  /// Directly used in [dispose] method.
  @internal
  late final List<void Function()> onDispose = [];

  /// [_readCache] is used to cache [_read] invocation results,
  /// since [read]s are stable over time.
  final _readCache = <ProviderBase, dynamic>{};

  _ReadResult<T> _read<T>(ProviderBase<T> provider) {
    if (providables.containsKey(provider)) {
      return _ReadResult(
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
        if (candidate._isScoped(result.dependencyNode)) {
          break;
        }
        candidate = candidate.parent!;
      }

      return candidate._mountProvider(result);
    } else {
      ProviderContainer candidate = this;
      final node = host.dependencies[provider.toScopable()]!;
      while (candidate != host) {
        if (candidate._isScoped(node)) {
          break;
        }

        candidate = candidate.parent!;
      }

      if (candidate != host) {
        final result = _create(provider);
        return candidate._mountProvider(result);
      } else {
        return host._read(provider);
      }
    }
  }

  /// Decides if [node] is scoped inside this container.
  /// Essentially it checks if one of [node.provider] dependencies is present in [overrides].
  bool _isScoped(_DependencyNode node) {
    final scopable = node.scopable;
    final isScopedDirectly = scopable is ProviderFactoryBase
        ? _factoryOverrides.keys.contains(scopable)
        : _providerOverrides.keys.contains(scopable);

    return isScopedDirectly || node.dependencies.any(_isScoped);
  }

  _CreateResult<T> _create<T>(ProviderBase<T> provider) => _circularDependencyCheck(
        lock: provider,
        () {
          final dependencies = HashSet<_DependencyNode>();

          final override = _findOverride<T>(provider);
          final overrideOrProvider = override ?? provider;

          final value = overrideOrProvider.create(<T>(ProviderBase<T> dependency) {
            final result = _read(dependency);
            dependencies.add(result.node);
            return result.value;
          });

          return _CreateResult(
            origin: provider,
            override: override,
            value: value,
            dependencyNode: _DependencyNode(
              scopable: provider.toScopable(),
              dependencies: dependencies,
            ),
          );
        },
      );

  _ReadResult<T> _mountProvider<T>(_CreateResult<T> result) {
    this
      ..dependencies[result.dependencyNode.scopable] = result.dependencyNode
      ..providables[result.origin] = result.value;

    final dispose = result.overrideOrProvider.dispose;
    if (dispose != null) {
      onDispose.add(() => dispose.call(result.value));
    }

    return _ReadResult(result.dependencyNode, result.value);
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

  _CreateResult<T> _circularDependencyCheck<T>(
    _CreateResult<T> Function() create, {
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

  /// Check if [provider]'s value is present inside this container.
  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return providables.containsKey(provider);
  }

  /// Amount of values instantiated inside this container.
  @visibleForTesting
  int providablesLength() => providables.length;
}

class _DependencyNode {
  final Set<_DependencyNode> dependencies;
  final MaybeScoped scopable;

  _DependencyNode({
    required this.dependencies,
    required this.scopable,
  });

  @override
  int get hashCode => scopable.hashCode;

  @override
  operator ==(Object? other) => other is _DependencyNode && other.scopable == scopable;
}

class _ReadResult<T> {
  final _DependencyNode node;
  final T value;

  _ReadResult(this.node, this.value);
}

class _CreateResult<T> {
  final ProviderBase<T> origin;
  final ProviderBase<T>? override;
  final T value;
  final _DependencyNode dependencyNode;

  ProviderBase<T> get overrideOrProvider => override ?? origin;

  _CreateResult({
    required this.origin,
    required this.override,
    required this.value,
    required this.dependencyNode,
  });
}

/// Thrown when circular dependency is detected.
class CircularDependencyException implements Exception {
  /// Contains information about participants of circular dependency.
  final String message;
  // ignore: public_member_api_docs
  CircularDependencyException(this.message);

  @override
  String toString() {
    return "CircularDependencyException: $message";
  }
}
