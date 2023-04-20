import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocConsumer<B extends StateStreamable<S>, S>
    extends flutter_bloc.BlocConsumer<B, S> {
  BlocConsumer({
    super.key,
    required super.builder,
    required super.listener,
    required B super.bloc,
    super.buildWhen,
    super.listenWhen,
  });
}
