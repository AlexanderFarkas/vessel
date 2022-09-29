import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

import 'bloc_listener.dart';

typedef BlocWidgetBuilder<S> = Widget Function(BuildContext context, S state);
typedef BlocBuilderCondition<S> = bool Function(S previous, S current);

class BlocBuilder<B extends BlocBase<S>, S> extends BlocBuilderBase<B, S> {
  /// {@macro bloc_builder}
  /// {@macro bloc_builder_build_when}
  const BlocBuilder({
    Key? key,
    required ProviderBase<B> provider,
    BlocBuilderCondition<S>? buildWhen,
    required this.builder,
  }) : super(key: key, provider: provider, buildWhen: buildWhen);

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final BlocWidgetBuilder<S> builder;

  @override
  Widget build(BuildContext context, S state) => builder(context, state);
}

abstract class BlocBuilderBase<B extends BlocBase<S>, S> extends StatefulWidget {
  const BlocBuilderBase({
    Key? key,
    required this.provider,
    this.buildWhen,
  }) : super(key: key);

  final ProviderBase<B> provider;

  final BlocBuilderCondition<S>? buildWhen;

  /// Returns a widget based on the `BuildContext` and current [state].
  Widget build(BuildContext context, S state);

  @override
  State<BlocBuilderBase<B, S>> createState() => _BlocBuilderBaseState<B, S>();
}

class _BlocBuilderBaseState<B extends BlocBase<S>, S> extends State<BlocBuilderBase<B, S>> {
  late B _bloc;
  late S _state;

  @override
  void initState() {
    super.initState();
    _bloc = widget.provider.of(context);
    _state = _bloc.state;
  }

  @override
  void didUpdateWidget(BlocBuilderBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.provider.of(context);
    final currentBloc = widget.provider.of(context);
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _state = _bloc.state;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.provider.of(context, listen: true);
    if (_bloc != bloc) {
      _bloc = bloc;
      _state = _bloc.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      provider: widget.provider,
      listenWhen: widget.buildWhen,
      listener: (context, state) => setState(() => _state = state),
      child: widget.build(context, _state),
    );
  }
}
