import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

import 'bloc_builder.dart';
import 'bloc_listener.dart';

class BlocConsumer<B extends BlocBase<S>, S> extends StatelessWidget {
  /// {@macro bloc_consumer}
  const BlocConsumer({
    Key? key,
    required this.provider,
    required this.builder,
    required this.listener,
    this.buildWhen,
    this.listenWhen,
  }) : super(key: key);

  /// The [provider] that the [BlocConsumer] will interact with.
  /// If omitted, [BlocConsumer] will automatically perform a lookup using
  /// `BlocProvider` and the current `BuildContext`.
  final ProviderBase<B> provider;

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final BlocWidgetBuilder<S> builder;

  /// Takes the `BuildContext` along with the [provider] `state`
  /// and is responsible for executing in response to `state` changes.
  final BlocWidgetListener<S> listener;

  /// Takes the previous `state` and the current `state` and is responsible for
  /// returning a [bool] which determines whether or not to trigger
  /// [builder] with the current `state`.
  final BlocBuilderCondition<S>? buildWhen;

  /// Takes the previous `state` and the current `state` and is responsible for
  /// returning a [bool] which determines whether or not to call [listener] of
  /// [BlocConsumer] with the current `state`.
  final BlocListenerCondition<S>? listenWhen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      provider: provider,
      builder: builder,
      buildWhen: (previous, current) {
        if (listenWhen?.call(previous, current) ?? true) {
          listener(context, current);
        }
        return buildWhen?.call(previous, current) ?? true;
      },
    );
  }
}
