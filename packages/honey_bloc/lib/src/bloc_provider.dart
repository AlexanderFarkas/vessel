// ignore_for_file: non_constant_identifier_names

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart' as flutter;
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:honey_bloc/src/bloc_builder.dart';
import 'package:honey_bloc/src/bloc_consumer.dart';
import 'package:honey_bloc/src/bloc_listener.dart';
import 'package:honey_bloc/src/bloc_selector.dart';

import 'package:honeycomb_flutter/honeycomb_flutter.dart';
import 'package:nested/nested.dart';

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
  flutter.Widget Builder({
    flutter.Key? key,
    flutter_bloc.BlocBuilderCondition<S>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<S> builder,
  }) {
    return flutter.Builder(
      key: key,
      builder: (context) => BlocBuilder<B, S>(
        bloc: of(context),
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }

  SingleChildWidget Listener({
    flutter.Key? key,
    flutter_bloc.BlocListenerCondition<S>? listenWhen,
    required flutter_bloc.BlocWidgetListener<S> listener,
    flutter.Widget? child,
  }) {
    return HoneycombBlocListener<B, S>(
      key: key,
      provider: this,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  flutter.Widget Consumer({
    flutter.Key? key,
    flutter_bloc.BlocListenerCondition<S>? listenWhen,
    required flutter_bloc.BlocWidgetListener<S> listener,
    flutter_bloc.BlocBuilderCondition<S>? buildWhen,
    required flutter_bloc.BlocWidgetBuilder<S> builder,
  }) {
    return flutter.Builder(
      key: key,
      builder: (context) => BlocConsumer<B, S>(
        bloc: of(context),
        buildWhen: buildWhen,
        builder: builder,
        listenWhen: listenWhen,
        listener: listener,
      ),
    );
  }

  flutter.Widget Selector<T>({
    flutter.Key? key,
    required flutter_bloc.BlocWidgetSelector<S, T> selector,
    required flutter_bloc.BlocWidgetBuilder<T> builder,
  }) {
    return flutter.Builder(
      key: key,
      builder: (context) => BlocSelector<B, S, T>(
        bloc: of(context),
        selector: selector,
        builder: builder,
      ),
    );
  }
}
