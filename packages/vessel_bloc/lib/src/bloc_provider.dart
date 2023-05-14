// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:vessel_bloc/src/bloc_listener.dart';
import 'package:vessel_bloc/src/bloc_selector.dart';

import 'package:vessel_flutter/vessel_flutter.dart';

import '../vessel_bloc.dart';

class BlocProvider<TBloc extends BlocBase<TState>, TState> extends SingleProviderBase<TBloc>
    with BlocBindingMixin<TBloc, TState> {
  BlocProvider(ProviderCreate<TBloc> create, {String? debugName})
      : super(
          create,
          dispose: (bloc) => bloc.close(),
          debugName: debugName,
        );

  static final factory = BlocProviderFactory.new;
}

class FactoryBlocProvider<TBloc extends BlocBase<TState>, TState, TParam>
    extends FactoryProviderBase<TBloc, TParam> with BlocBindingMixin<TBloc, TState> {
  FactoryBlocProvider(
    super.create, {
    required super.factory,
    required super.debugName,
    required super.dispose,
    required super.param,
  });
}

class BlocProviderFactory<TBloc extends BlocBase<TState>, TState, TParam>
    extends ProviderFactoryBase<FactoryBlocProvider<TBloc, TState, TParam>, TBloc, TParam> {
  BlocProviderFactory(super.create, {super.dispose, super.debugName});

  @override
  FactoryBlocProvider<TBloc, TState, TParam> call(TParam param) {
    return FactoryBlocProvider(
      (read) => create(read, param),
      factory: this,
      debugName: debugName,
      dispose: dispose,
      param: param,
    );
  }
}

mixin BlocBindingMixin<TBloc extends BlocBase<TState>, TState> implements ProviderBase<TBloc> {
  Widget builder({
    Key? key,
    flutter_bloc.BlocBuilderCondition<TState>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<TState> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocBuilder<TBloc, TState>(
        bloc: of(context, listen: true),
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
    return VesselBlocListener<TBloc, TState>(
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
      builder: (context) => BlocConsumer<TBloc, TState>(
        bloc: of(context, listen: true),
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
      builder: (context) => BlocSelector<TBloc, TState, TSelected>(
        bloc: of(context, listen: true),
        selector: selector,
        builder: builder,
      ),
    );
  }
}
