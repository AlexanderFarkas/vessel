import 'package:flutter/material.dart';
import 'package:vessel_flutter/vessel_flutter.dart';

final provider = Provider((read) => ValueNotifier(0));

void main() {
  return runApp(
    ProviderScope(
      adapters: [ValueNotifierAdapter()],
      child: provider.builder(
        builder: (_, value, __) => Text("$value"),
      ),
    ),
  );
}

class ValueNotifierAdapter extends ProviderAdapter<ValueNotifier> {
  @override
  void dispose(ValueNotifier providerValue) {
    return providerValue.dispose();
  }
}

extension<T> on ProviderBase<ValueNotifier<T>> {
  Widget builder({required ValueWidgetBuilder<T> builder}) => _ValueNotifierProviderBuilder(
        provider: this,
        builder: builder,
      );
}

class _ValueNotifierProviderBuilder<T> extends StatelessWidget {
  final ProviderBase<ValueNotifier<T>> provider;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;

  const _ValueNotifierProviderBuilder({
    super.key,
    required this.builder,
    required this.provider,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: provider.of(context),
      builder: builder,
      child: child,
    );
  }
}
