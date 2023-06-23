part of 'internal_api.dart';

class ScopeOverride extends Override {
  final MaybeScoped _origin;

  ScopeOverride(this._origin);
}

class ProviderOverride<TValue> extends Override {
  final SingleProviderBase<TValue> _origin;
  final ProviderBase<TValue> _override;

  ProviderOverride(
      {required SingleProviderBase<TValue> origin, required ProviderBase<TValue> override})
      : _origin = origin,
        _override = override;
}

typedef FactoryOverrideFn<TValue, TArg> = ProviderBase<TValue> Function(TArg);

class FactoryOverride<TProvider extends FactoryProviderBase<TValue, TParam>, TValue, TParam>
    extends Override {
  final ProviderFactoryBase<TProvider, TValue, TParam> _origin;
  final FactoryOverrideFn<TValue, TParam> _override;

  FactoryOverride({
    required ProviderFactoryBase<TProvider, TValue, TParam> origin,
    required FactoryOverrideFn<TValue, TParam> override,
  })  : _origin = origin,
        _override = override;

  ProviderBase<TValue> getOverride(FactoryProviderBase<TValue, TParam> provider) {
    return _override(provider.param);
  }
}
