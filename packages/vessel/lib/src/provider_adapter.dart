part of 'internal_api.dart';

abstract class ProviderAdapter<T> {
  const ProviderAdapter();

  bool isAdaptable(ProviderBase object) {
    return object is ProviderBase<T>;
  }

  /// Defines custom dispose behavior for providers of type [T]
  FutureOr<void> dispose(T providerValue) {}
}
