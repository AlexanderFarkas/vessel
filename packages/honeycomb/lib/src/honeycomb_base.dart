import 'package:meta/meta.dart';

ProviderBase? _circularDependencySentinel;

class Container {
  final Container? parent;
  final int rank;

  final Map<ProviderBase, ProviderWithState> _providables = {};
  final Map<ProviderFactory, FactoryOverride> _factoryOverrides = {};
  final Map<ProviderBase, ProviderOverride> _providerOverrides = {};

  Container({
    this.parent,
    List<Override> overrides = const [],
  }) : rank = (parent?.rank ?? 0) + 1 {
    for (final override in overrides) {
      _setOverride(override);
    }
  }

  T read<T>(ProviderBase<T> provider) {
    return _readWithState(provider, this).state;
  }

  ProviderWithState _readWithState<T>(ProviderBase<T> provider, Container source) {
    final identifier = provider;

    if (_providables.containsKey(identifier)) {
      return _providables[identifier]!;
    }

    ProviderWithState<T> create(ProviderBase<T> provider, {required bool isOverride}) {
      if (_circularDependencySentinel == provider) {
        throw CircularDependencyException("There is a circular dependency on $provider");
      }

      _circularDependencySentinel ??= provider;

      try {
        final dependencies = <ProviderWithState>{};

        final created = provider.create(<K>(ProviderBase<K> provider) {
          final providerWithState = source._readWithState(provider, source);
          dependencies.add(providerWithState);
          dependencies.addAll(providerWithState.dependencies);

          return providerWithState.state;
        });

        return ProviderWithState<T>(
          provider: provider,
          state: created,
          dependencies: dependencies,
          owner: this,
          isOverride: isOverride,
        );
      } finally {
        _circularDependencySentinel = null;
      }
    }

    final overriddenProvider = _findOverride(provider);
    if (overriddenProvider != null) {
      return _set(identifier, create(overriddenProvider, isOverride: true));
    }

    if (parent != null) {
      return parent!._readWithState(provider, source);
    } else {
      final newProvider = create(
        provider,
        isOverride: false,
      );

      var lowestContainerWithOverride = this;
      for (final dependency in newProvider.dependencies) {
        if (dependency.owner.rank > lowestContainerWithOverride.rank) {
          lowestContainerWithOverride = dependency.owner;
        }
      }

      return lowestContainerWithOverride._set(identifier, newProvider);
    }
  }

  void dispose() {
    for (final providerWithState in _providables.values) {
      providerWithState.dispose();
    }
  }

  @visibleForTesting
  bool isPresent(ProviderBase provider) {
    return _providables.containsKey(provider);
  }

  @visibleForTesting
  int? dependencyCount(ProviderBase provider) {
    return _providables[provider]?.dependencies.length;
  }

  ProviderBase<T>? _findOverride<T>(ProviderBase<T> provider) {
    ProviderBase<dynamic>? overridden = provider is FactoryProvider<T, dynamic>
        ? _factoryOverrides[provider.factory]?.getOverride(provider)
        : _providerOverrides[provider]?._override;

    return overridden as ProviderBase<T>?;
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

  ProviderWithState<T> _set<T>(ProviderBase<T> key, ProviderWithState<T> value) {
    return _providables[key] = value;
  }
}

class ProviderWithState<TState> {
  final ProviderBase<TState> provider;
  final TState state;
  final Set<ProviderWithState> dependencies;
  final Container owner;
  final bool isOverride;

  ProviderWithState({
    required this.provider,
    required this.state,
    required this.dependencies,
    required this.owner,
    required this.isOverride,
  });

  @override
  String toString() {
    return provider.toString();
  }

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
  ProviderOrFactory({required this.dispose});
}

abstract class ProviderBase<T> extends ProviderOrFactory<T> implements ProviderOverride<T> {
  final ProviderCreate<T> create;
  final String? debugName;

  @override
  ProviderBase<T> get _origin => this;

  @override
  ProviderBase<T> get _override => this;

  ProviderBase(
    this.create, {
    required this.debugName,
    required Dispose<T>? dispose,
  }) : super(
          dispose: dispose,
        );
}

class Provider<T> extends ProviderBase<T> with _DebugMixin {
  Provider(
    ProviderCreate<T> create, {
    Dispose<T>? dispose,
    String? debugName,
  }) : super(
          create,
          dispose: dispose,
          debugName: debugName,
        );

  ProviderOverride<T> overrideWith(Provider<T> provider) {
    return ProviderOverride(
      origin: this,
      override: provider,
    );
  }

  @override
  String toString() {
    return "$runtimeType$_debugString";
  }
}

abstract class ProviderFactoryBase<TState, TArg> extends ProviderOrFactory<TState>
    implements FactoryOverride<TState, TArg> {
  ProviderFactoryBase({required super.dispose});
}

class ProviderFactory<T, K> extends ProviderFactoryBase<T, K> with FactoryOverrideMixin<T, K> {
  final ProviderFactoryCreate<T, K> create;
  final String? debugName;
  ProviderFactory(
    this.create, {
    super.dispose,
    this.debugName,
  });

  @override
  ProviderFactory<T, K> get _origin => this;

  @override
  FactoryOverrideFn<T, K> get _override => call;

  ProviderBase<T> call(K param) {
    return FactoryProvider<T, K>(
      (get) => create(get, param),
      factory: this,
      debugName: debugName,
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

class FactoryProvider<T, K> extends ProviderBase<T> with _DebugMixin {
  final K param;
  final ProviderFactory<T, K> factory;
  FactoryProvider(
    super.create, {
    required this.factory,
    required super.debugName,
    required super.dispose,
    required this.param,
  });

  @override
  int get hashCode => identityHashCode(factory) ^ param.hashCode;

  @override
  bool operator ==(Object other) {
    return other is FactoryProvider && other.factory == factory && other.param == param;
  }

  @override
  String toString() {
    return "${factory.runtimeType}$_debugString";
  }
}

mixin _DebugMixin {
  abstract final String? debugName;
  String get _debugString => "(${debugName != null ? '$debugName:' : ''}${_shortHash(this)})";

  String _shortHash(Object? object) {
    return object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
  }
}

class CircularDependencyException implements Exception {
  final String message;
  CircularDependencyException(this.message);

  @override
  String toString() {
    return "CircularDependencyException: $message";
  }
}
