// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:vessel_bloc/src/bloc_listener.dart';
import 'package:vessel_bloc/src/bloc_selector.dart';

import 'package:vessel_flutter/vessel_flutter.dart';

import '../vessel_bloc.dart';

class BlocProvider<B extends BlocBase<S>, S> extends SingleProviderBase<B>
    with BlocBindingMixin<B, S> {
  BlocProvider(ProviderCreate<B> create, {String? debugName})
      : super(
          create,
          dispose: (bloc) => bloc.close(),
          debugName: debugName,
        );

  static BlocProviderFactory<B, S, K> factory<B extends BlocBase<S>, S, K>(
    ProviderFactoryCreate<B, K> create, {
    String? debugName,
  }) =>
      BlocProviderFactory<B, S, K>(
        create,
        dispose: (bloc) => bloc.close(),
        debugName: debugName,
      );
}

class FactoryBlocProvider<B extends BlocBase<S>, S, TParam> extends FactoryProviderBase<B, TParam>
    with BlocBindingMixin<B, S> {
  FactoryBlocProvider(
    super.create, {
    required super.factory,
    required super.debugName,
    required super.dispose,
    required super.param,
  });
}

class BlocProviderFactory<B extends BlocBase<S>, S, K>
    extends ProviderFactoryBase<FactoryBlocProvider<B, S, K>, B, K> {
  BlocProviderFactory(super.create, {required super.dispose, required super.debugName});

  @override
  FactoryBlocProvider<B, S, K> call(K param) {
    return FactoryBlocProvider(
      (read) => create(read, param),
      factory: this,
      debugName: debugName,
      dispose: dispose,
      param: param,
    );
  }
}

mixin BlocBindingMixin<B extends BlocBase<S>, S> implements ProviderBase<B> {
  Widget builder({
    Key? key,
    flutter_bloc.BlocBuilderCondition<S>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<S> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocBuilder<B, S>(
        bloc: of(context, listen: true),
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }

  BlocListenerSingleChildMixin listener({
    Key? key,
    flutter_bloc.BlocListenerCondition<S>? listenWhen,
    required flutter_bloc.BlocWidgetListener<S> listener,
    Widget? child,
  }) {
    return VesselBlocListener<B, S>(
      key: key,
      provider: this,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  Widget consumer({
    Key? key,
    flutter_bloc.BlocListenerCondition<S>? listenWhen,
    required flutter_bloc.BlocWidgetListener<S> listener,
    flutter_bloc.BlocBuilderCondition<S>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<S> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocConsumer<B, S>(
        bloc: of(context, listen: true),
        buildWhen: buildWhen,
        builder: builder,
        listenWhen: listenWhen,
        listener: listener,
      ),
    );
  }

  Widget selector<T>({
    Key? key,
    required flutter_bloc.BlocWidgetSelector<S, T> selector,
    required flutter_bloc.BlocWidgetBuilder<T> builder,
  }) {
    return Builder(
      key: key,
      builder: (context) => BlocSelector<B, S, T>(
        bloc: of(context, listen: true),
        selector: selector,
        builder: builder,
      ),
    );
  }
}
