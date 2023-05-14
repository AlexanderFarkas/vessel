import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocBuilder<TBloc extends StateStreamable<TState>, TState>
    extends flutter_bloc.BlocBuilder<TBloc, TState> {
  BlocBuilder({
    super.key,
    required super.builder,
    required TBloc super.bloc,
    super.buildWhen,
  });
}
