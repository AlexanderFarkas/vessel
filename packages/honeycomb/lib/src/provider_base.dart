part of 'internal_api.dart';

typedef Dispose<T> = void Function(T state);
typedef ReadProvider = T Function<T>(ProviderBase<T> provider);
typedef ProviderCreate<T> = T Function(ReadProvider read);
typedef ProviderFactoryCreate<T, K> = T Function(ReadProvider read, K param);

abstract class MaybeScoped {}

abstract class Override {}

abstract class ProviderOrFactory<T> {
  final Dispose<T>? dispose;
  ProviderOrFactory({required this.dispose});
}

abstract class ProviderBase<T> extends ProviderOrFactory<T> with _DebugMixin {
  final ProviderCreate<T> create;

  @override
  final String? debugName;

  ProviderBase(
    this.create, {
    required this.debugName,
    required Dispose<T>? dispose,
  }) : super(dispose: dispose);

  @internal
  MaybeScoped toScopable() {
    if (this is FactoryProviderBase<T, dynamic>) {
      return (this as FactoryProviderBase).factory;
    } else if (this is SingleProviderBase) {
      return this as SingleProviderBase;
    } else {
      throw UnsupportedError("To scopable");
    }
  }
}

abstract class SingleProviderBase<T> extends ProviderBase<T> implements MaybeScoped {
  SingleProviderBase(
    super.create, {
    required super.debugName,
    required super.dispose,
  });

  @nonVirtual
  ProviderOverride<T> overrideWith(ProviderBase<T> provider) {
    return ProviderOverride(
      origin: this,
      override: provider,
    );
  }

  @nonVirtual
  ProviderOverride<T> scope() => ProviderOverride(origin: this, override: this);

  @override
  String toString() {
    return "$runtimeType$_debugString";
  }
}

abstract class ProviderFactoryBase<TProvider extends FactoryProviderBase<TState, TParam>, TState,
    TParam> extends ProviderOrFactory<TState> implements MaybeScoped {
  final ProviderFactoryCreate<TState, TParam> create;
  final String? debugName;

  ProviderFactoryBase(
    this.create, {
    required super.dispose,
    required this.debugName,
  });

  TProvider call(TParam param);

  @nonVirtual
  FactoryOverride<TProvider, TState, TParam> overrideWith(
    ProviderBase<TState> Function(TParam) providerBuilder,
  ) {
    return FactoryOverride(
      origin: this,
      override: providerBuilder,
    );
  }

  @nonVirtual
  FactoryOverride<TProvider, TState, TParam> scope() =>
      FactoryOverride(origin: this, override: this);
}

class FactoryProviderBase<TState, TParam> extends ProviderBase<TState> {
  final TParam param;
  final ProviderFactoryBase<FactoryProviderBase<TState, TParam>, TState, TParam> factory;

  FactoryProviderBase(
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
    return other is FactoryProviderBase && other.factory == factory && other.param == param;
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
