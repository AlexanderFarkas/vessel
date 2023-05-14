import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocConsumer<TBloc extends StateStreamable<TState>, TState>
    extends flutter_bloc.BlocConsumer<TBloc, TState> {
  BlocConsumer({
    super.key,
    required super.builder,
    required super.listener,
    required TBloc super.bloc,
    super.buildWhen,
    super.listenWhen,
  });
}
