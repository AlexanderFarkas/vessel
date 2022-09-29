import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';
import 'package:nested/nested.dart';

typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);
typedef BlocListenerCondition<S> = bool Function(S previous, S current);

class BlocListener<B extends BlocBase<S>, S> extends SingleChildStatefulWidget {
  final ProviderBase<B> provider;
  final Widget? child;
  final BlocWidgetListener<S> listener;
  final BlocListenerCondition<S>? listenWhen;

  const BlocListener({
    Key? key,
    required this.provider,
    required this.listener,
    this.listenWhen,
    this.child,
  }) : super(key: key, child: child);

  @override
  SingleChildState<BlocListener<B, S>> createState() => _BlocListenerState();
}

class _BlocListenerState<B extends BlocBase<S>, S> extends SingleChildState<BlocListener<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _bloc;
  late S _previousState;

  @override
  void initState() {
    super.initState();
    _bloc = widget.provider.of(context);
    _previousState = _bloc.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocListener<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.provider.of(context);
    final currentBloc = widget.provider.of(context);
    if (oldBloc != currentBloc) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = currentBloc;
        _previousState = _bloc.state;
      }
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.provider.of(context, listen: true);
    if (_bloc != bloc) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = bloc;
        _previousState = _bloc.state;
      }
      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of MultiBlocListener must specify a child''',
    );

    return child!;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
        widget.listener(context, state);
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
