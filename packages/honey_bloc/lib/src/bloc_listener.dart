import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as flutter_bloc;
import 'package:honey_bloc/honey_bloc.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';
import 'package:nested/nested.dart';
import 'package:meta/meta.dart';

class BlocListener<B extends StateStreamable<S>, S> extends flutter_bloc.BlocListener<B, S> with BlocListenerSingleChildMixin {
  BlocListener({
    super.key,
    required super.listener,
    required B super.bloc,
    super.listenWhen,
    super.child,
  });
}

@internal
class HoneycombBlocListener<B extends BlocBase<S>, S> extends SingleChildStatelessWidget with BlocListenerSingleChildMixin {
  final ProviderBase<B> provider;
  final flutter_bloc.BlocWidgetListener<S> listener;

  final flutter_bloc.BlocListenerCondition<S>? listenWhen;

  HoneycombBlocListener({
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
