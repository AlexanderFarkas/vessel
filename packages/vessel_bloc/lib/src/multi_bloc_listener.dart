import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

mixin BlocListenerSingleChildMixin on SingleChildWidget {}

class MultiBlocListener extends StatelessWidget {
  final List<BlocListenerSingleChildMixin> listeners;
  final Widget child;
  const MultiBlocListener({
    super.key,
    required this.listeners,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Nested(
      children: listeners,
      child: child,
    );
  }
}
