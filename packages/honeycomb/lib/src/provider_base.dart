part of 'internal_api.dart';

typedef Dispose<T> = void Function(T value);
typedef ReadProvider = T Function<T>(ProviderBase<T> provider);
typedef ProviderCreate<T> = T Function(ReadProvider read);
typedef ProviderFactoryCreate<T, K> = T Function(ReadProvider read, K param);

/// Indicates that entity can be scoped or overriden
abstract class MaybeScoped {}

/// Base class for all possible overrides
abstract class Override {}

/// Base class for both providers and factories
abstract class ProviderOrFactory<T> {
  /// Decides how to dispose values produces by this [ProviderOrFactory]
  final Dispose<T>? dispose;
  // ignore: public_member_api_docs
  ProviderOrFactory({required this.dispose});
}

/// Base class for all providers
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

/// Base class for non-factory providers.
///
/// Non-factory providers are basically singletons in the scope of container
/// ```dart
/// final myProvider = Provider((read) => MySingleton());
/// ```
abstract class SingleProviderBase<T> extends ProviderBase<T> implements MaybeScoped {
  // ignore: public_member_api_docs
  SingleProviderBase(
    super.create, {
    required super.debugName,
    required super.dispose,
  });

  /// Creates [ProviderOverride], which is then can be used in [ProviderContainer.overrides]
  /// to intercept `container.read(oldProvider)` and replace `oldProvider` with [provider].
  /// ```dart
  /// final rootContainer = ProviderContainer();
  /// final container = ProviderContainer(
  ///   parent: rootContainer,
  ///   overrides: [myProvider.overrideWith(anotherProvider)],
  /// );
  /// 
  /// rootContainer.read(myProvider) // myProviderInstance#1
  /// container.read(myProvider) // anotherProviderInstance#1
  /// ```
  @nonVirtual
  ProviderOverride<T> overrideWith(ProviderBase<T> provider) {
    return ProviderOverride(
      origin: this,
      override: provider,
    );
  }

  /// Creates self-override, which means [provider]'s value will be recreated and scoped 
  /// inside container, owning this override
  /// ```dart
  /// final rootContainer = ProviderContainer();
  /// final container = ProviderContainer(
  ///   parent: rootContainer,
  ///   overrides: [myProvider.scoped()],
  /// );
  /// 
  /// rootContainer.read(myProvider) // instance#1
  /// container.read(myProvider) // instance#2
  /// ```
  @nonVirtual
  ProviderOverride<T> scope() => overrideWith(this);

  @override
  String toString() {
    return "$runtimeType$_debugString";
  }
}

abstract class ProviderFactoryBase<TProvider extends FactoryProviderBase<TValue, TParam>, TValue,
    TParam> extends ProviderOrFactory<TValue> implements MaybeScoped {
  final ProviderFactoryCreate<TValue, TParam> create;
  final String? debugName;

  ProviderFactoryBase(
    this.create, {
    required super.dispose,
    required this.debugName,
  });

  TProvider call(TParam param);

  @nonVirtual
  FactoryOverride<TProvider, TValue, TParam> overrideWith(
    ProviderBase<TValue> Function(TParam) providerBuilder,
  ) {
    return FactoryOverride(
      origin: this,
      override: providerBuilder,
    );
  }

  @nonVirtual
  FactoryOverride<TProvider, TValue, TParam> scope() => overrideWith(this);
}

class FactoryProviderBase<TValue, TParam> extends ProviderBase<TValue> {
  final TParam param;
  final ProviderFactoryBase<FactoryProviderBase<TValue, TParam>, TValue, TParam> factory;

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
