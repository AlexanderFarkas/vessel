// ignore_for_file: non_constant_identifier_names

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:honey_bloc/src/bloc_builder.dart';
import 'package:honey_bloc/src/bloc_consumer.dart';
import 'package:honey_bloc/src/bloc_listener.dart';
import 'package:honey_bloc/src/bloc_selector.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

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
  BlocBuilder<B, S> Builder({
    Key? key,
    BlocBuilderCondition<S>? buildWhen,
    required BlocWidgetBuilder<S> builder,
  }) {
    return BlocBuilder<B, S>(
      key: key,
      provider: this,
      builder: builder,
      buildWhen: buildWhen,
    );
  }

  BlocListener<B, S> Listener({
    Key? key,
    BlocListenerCondition<S>? listenWhen,
    required BlocWidgetListener<S> listener,
    Widget? child,
  }) {
    return BlocListener<B, S>(
      key: key,
      provider: this,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  BlocConsumer<B, S> Consumer({
    Key? key,
    BlocListenerCondition<S>? listenWhen,
    required BlocWidgetListener<S> listener,
    BlocBuilderCondition<S>? buildWhen,
    required BlocWidgetBuilder<S> builder,
  }) {
    return BlocConsumer<B, S>(
      key: key,
      provider: this,
      buildWhen: buildWhen,
      builder: builder,
      listenWhen: listenWhen,
      listener: listener,
    );
  }

  BlocSelector<B, S, T> Selector<T>({
    Key? key,
    required BlocWidgetSelector<S, T> selector,
    required BlocWidgetBuilder<T> builder,
  }) {
    return BlocSelector<B, S, T>(
      key: key,
      provider: this,
      selector: selector,
      builder: builder,
    );
  }
}
