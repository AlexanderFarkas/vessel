part of 'internal_api.dart';


class ProviderOverride<TState> extends Override {
  final SingleProviderBase<TState> _origin;
  final ProviderBase<TState> _override;

  ProviderOverride(
      {required SingleProviderBase<TState> origin, required ProviderBase<TState> override})
      : _origin = origin,
        _override = override;
}

typedef FactoryOverrideFn<TState, TArg> = ProviderBase<TState> Function(TArg);

class FactoryOverride<TProvider extends FactoryProviderBase<TState, TParam>, TState, TParam>
    extends Override {
  final ProviderFactoryBase<TProvider, TState, TParam> _origin;
  final FactoryOverrideFn<TState, TParam> _override;

  FactoryOverride({
    required ProviderFactoryBase<TProvider, TState, TParam> origin,
    required FactoryOverrideFn<TState, TParam> override,
  })  : _origin = origin,
        _override = override;

  ProviderBase<TState> getOverride(FactoryProviderBase<TState, TParam> provider) {
    return _override(provider.param);
  }
}
