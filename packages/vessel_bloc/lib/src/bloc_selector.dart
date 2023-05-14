import 'package:vessel_bloc/vessel_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocSelector<TBloc extends StateStreamable<TState>, TState, TSelected>
    extends flutter_bloc.BlocSelector<TBloc, TState, TSelected> {
  BlocSelector({
    super.key,
    required super.selector,
    required super.builder,
    required TBloc super.bloc,
  });
}
