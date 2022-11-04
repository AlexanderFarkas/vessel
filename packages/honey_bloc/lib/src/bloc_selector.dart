import 'package:honey_bloc/honey_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;

class BlocSelector<B extends StateStreamable<S>, S, T> extends flutter_bloc.BlocSelector<B, S, T> {
  BlocSelector({
    super.key,
    required super.selector,
    required super.builder,
    required B super.bloc,
  });
}
