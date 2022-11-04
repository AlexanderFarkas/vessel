import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocBuilder<B extends StateStreamable<S>, S> extends flutter_bloc.BlocBuilder<B, S> {
  BlocBuilder({
    super.key,
    required super.builder,
    required B super.bloc,
    super.buildWhen,
  });
}
