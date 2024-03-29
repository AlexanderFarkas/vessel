part of 'internal_api.dart';

final class _ProviderFactory<TValue, TParam>
    extends ProviderFactoryBase<FactoryProvider<TValue, TParam>, TValue, TParam> {
  _ProviderFactory(
    super.create, {
    super.dispose,
    super.debugName,
  });

  @override
  FactoryProvider<TValue, TParam> call(TParam param) {
    return FactoryProvider<TValue, TParam>(
      (get) => create(get, param),
      factory: this,
      debugName: debugName,
      dispose: dispose,
      param: param,
    );
  }
}

final class Provider<T> extends SingleProviderBase<T> {
  Provider(
    ProviderCreate<T> create, {
    Dispose<T>? dispose,
    String? debugName,
  }) : super(
          create,
          dispose: dispose,
          debugName: debugName,
        );

  /// Creates provider factory.
  ///
  /// Calling `provider(param)` returns new provider, which can be read
  /// Example: `container.read(provider(param))`
  static final factory = _ProviderFactory.new;
}

final class FactoryProvider<T, K> extends FactoryProviderBase<T, K> {
  FactoryProvider(
    super.create, {
    required super.factory,
    required super.debugName,
    required super.dispose,
    required super.param,
  });
}
