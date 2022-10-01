import 'package:flutter/widgets.dart';
import 'package:honey_bloc/honey_bloc.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

typedef BlocWidgetSelector<S, T> = T Function(S state);

class BlocSelector<B extends BlocBase<S>, S, T> extends StatefulWidget {
  const BlocSelector({
    Key? key,
    required this.provider,
    required this.selector,
    required this.builder,
  }) : super(key: key);

  final ProviderBase<B> provider;

  /// The [builder] function which will be invoked
  /// when the selected state changes.
  /// The [builder] takes the [BuildContext] and selected `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [BlocBuilder].
  final BlocWidgetBuilder<T> builder;

  /// The [selector] function which will be invoked on each widget build
  /// and is responsible for returning a selected value of type [T] based on
  /// the current state.
  final BlocWidgetSelector<S, T> selector;

  @override
  State<BlocSelector<B, S, T>> createState() => _BlocSelectorState<B, S, T>();
}

class _BlocSelectorState<B extends BlocBase<S>, S, T>
    extends State<BlocSelector<B, S, T>> {
  late B _bloc;
  late T _state;

  @override
  void initState() {
    super.initState();
    _bloc = widget.provider.of(context);
    _state = widget.selector(_bloc.state);
  }

  @override
  void didUpdateWidget(BlocSelector<B, S, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.provider.of(context);
    final currentBloc = widget.provider.of(context);
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _state = widget.selector(_bloc.state);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.provider.of(context, listen: true);
    if (_bloc != bloc) {
      _bloc = bloc;
      _state = widget.selector(_bloc.state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      provider: widget.provider,
      listener: (context, state) {
        final selectedState = widget.selector(state);
        if (_state != selectedState) setState(() => _state = selectedState);
      },
      child: widget.builder(context, _state),
    );
  }
}