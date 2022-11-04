import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

final provider = ValueNotifierProvider((read) => ValueNotifier(0));

void main() {
  return runApp(
    ProviderScope(
      child: provider.Builder(
        builder: (_, value, __) => Text("$value"),
      ),
    ),
  );
}

class ValueNotifierProvider<T> extends Provider<ValueNotifier<T>> {
  ValueNotifierProvider(
    ProviderCreate<ValueNotifier<T>> create, {
    String? debugName,
  }) : super(
          create,
          dispose: (vn) => vn.dispose(),
          debugName: debugName,
        );


  // ignore: non_constant_identifier_names
  Widget Builder({
    required ValueWidgetBuilder<T> builder,
    Widget? child,
  }) =>
      _ValueNotifierProviderBuilder(
        provider: this,
        builder: builder,
      );
}

class _ValueNotifierProviderBuilder<T> extends StatelessWidget {
  final ValueNotifierProvider<T> provider;
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
