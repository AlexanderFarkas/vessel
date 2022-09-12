part of '../honeycomb.dart';

class ProviderWithState<TState> {
  final ProviderBase<TState> provider;
  final TState state;
  final Set<ProviderBase> dependencies;
  final ProviderContainer owner;

  ProviderWithState({
    required this.provider,
    required this.state,
    required this.dependencies,
    required this.owner,
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

class FactoryOverride<TState, TArg> extends Override {
  final ProviderFactory<TState, TArg> _origin;
  final FactoryOverrideFn<TState, TArg> _override;

  FactoryOverride({
    required ProviderFactory<TState, TArg> origin,
    required FactoryOverrideFn<TState, TArg> override,
  })  : _origin = origin,
        _override = override;

  ProviderBase<TState> getOverride(FactoryProvider<TState, TArg> provider) {
    return _override(provider.param);
  }
}

typedef Dispose<T> = void Function(T state);
typedef ReadProvider = T Function<T>(ProviderBase<T> provider);
typedef ProviderCreate<T> = T Function(ReadProvider read);
typedef ProviderFactoryCreate<T, K> = T Function(ReadProvider read, K param);

abstract class MaybeScoped {}

abstract class ProviderOrFactory<T> {
  final Dispose<T>? dispose;
  ProviderOrFactory({required this.dispose});
}

abstract class ProviderBase<T> extends ProviderOrFactory<T> {
  final ProviderCreate<T> create;
  final String? debugName;

  ProviderBase(
    this.create, {
    required this.debugName,
    required Dispose<T>? dispose,
  }) : super(
          dispose: dispose,
        );
}

class Provider<T> extends ProviderBase<T> with _DebugMixin implements MaybeScoped {
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

class ProviderFactory<T, K> extends ProviderOrFactory<T> implements MaybeScoped {
  final ProviderFactoryCreate<T, K> create;
  final String? debugName;
  ProviderFactory(
    this.create, {
    super.dispose,
    this.debugName,
  });

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
    return FactoryOverride(
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
