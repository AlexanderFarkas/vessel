// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:vessel_bloc/src/bloc_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:vessel_bloc/src/bloc_selector.dart';

import 'package:vessel_flutter/vessel_flutter.dart';

import '../vessel_bloc.dart';

final class BlocProviderAdapter extends ProviderAdapter<BlocBase> {
  const BlocProviderAdapter();

  @override
  Future<void> dispose(BlocBase providerValue) {
    return providerValue.close();
  }
}

extension BlocBindings<TState> on ProviderBase<BlocBase<TState>> {
  Widget builder({
    Key? key,
    bool Function(TState? prev, TState state)? buildWhen,
    required Widget Function(BuildContext context, TState state) builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocBuilder<BlocBase<TState>, TState>(
        bloc: context.dependOn(this),
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }

  BlocListenerSingleChildMixin listener({
    Key? key,
    flutter_bloc.BlocListenerCondition<TState>? listenWhen,
    required flutter_bloc.BlocWidgetListener<TState> listener,
    Widget? child,
  }) {
    return VesselBlocListener<BlocBase<TState>, TState>(
      key: key,
      provider: this,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  Widget consumer({
    Key? key,
    flutter_bloc.BlocListenerCondition<TState>? listenWhen,
    required flutter_bloc.BlocWidgetListener<TState> listener,
    flutter_bloc.BlocBuilderCondition<TState>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<TState> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocConsumer<BlocBase<TState>, TState>(
        bloc: context.dependOn(this),
        buildWhen: buildWhen,
        builder: builder,
        listenWhen: listenWhen,
        listener: listener,
      ),
    );
  }

  Widget selector<TSelected>({
    Key? key,
    required flutter_bloc.BlocWidgetSelector<TState, TSelected> selector,
    required flutter_bloc.BlocWidgetBuilder<TSelected> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocSelector<BlocBase<TState>, TState, TSelected>(
        bloc: context.dependOn(this),
        selector: selector,
        builder: builder,
      ),
    );
  }
}
