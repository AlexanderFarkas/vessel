import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:vessel_bloc/vessel_bloc.dart';
import 'package:vessel_flutter/vessel_flutter.dart';
import 'package:nested/nested.dart';
import 'package:meta/meta.dart';

class BlocListener<TBloc extends StateStreamable<TState>, TState>
    extends flutter_bloc.BlocListener<TBloc, TState> with BlocListenerSingleChildMixin {
  BlocListener({
    super.key,
    required super.listener,
    required TBloc super.bloc,
    super.listenWhen,
    super.child,
  });
}

@internal
class VesselBlocListener<TBloc extends BlocBase<TState>, TState> extends SingleChildStatelessWidget
    with BlocListenerSingleChildMixin {
  final ProviderBase<TBloc> provider;
  final flutter_bloc.BlocWidgetListener<TState> listener;

  final flutter_bloc.BlocListenerCondition<TState>? listenWhen;

  VesselBlocListener({
    required super.key,
    required super.child,
    required this.provider,
    required this.listener,
    required this.listenWhen,
  });

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return BlocListener(
      bloc: provider.of(context, listen: true),
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }
}
