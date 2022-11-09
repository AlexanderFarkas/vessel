part of 'internal_api.dart';

class ProviderFactory<TValue, TParam> extends ProviderFactoryBase<
    FactoryProvider<TValue, TParam>, TValue, TParam> {
  ProviderFactory(
    super.create, {
    required super.dispose,
    required super.debugName,
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

class Provider<T> extends SingleProviderBase<T> {
  Provider(
    ProviderCreate<T> create, {
    Dispose<T>? dispose,
    String? debugName,
  }) : super(
          create,
          dispose: dispose,
          debugName: debugName,
        );

  static ProviderFactory<T, K> factory<T, K>(
    ProviderFactoryCreate<T, K> create, {
    Dispose<T>? dispose,
    String? debugName,
  }) =>
      ProviderFactory<T, K>(
        create,
        dispose: dispose,
        debugName: debugName,
      );
}

class FactoryProvider<T, K> extends FactoryProviderBase<T, K> {
  FactoryProvider(
    super.create, {
    required super.factory,
    required super.debugName,
    required super.dispose,
    required super.param,
  });
}
