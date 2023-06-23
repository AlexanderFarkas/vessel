import 'package:flutter/widgets.dart';

import 'package:vessel/vessel.dart';

class ProviderScope extends StatefulWidget {
  final List<Override> overrides;
  final List<ProviderAdapter> adapters;
  final ProviderContainer? parent;
  final Widget child;
  const ProviderScope({
    Key? key,
    this.overrides = const [],
    this.adapters = const [],
    required this.child,
    this.parent,
  }) : super(key: key);

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  late final ProviderContainer _container;

  @override
  void didChangeDependencies() {
    final parent = widget.parent ?? UncontrolledProviderScope._of(context, listen: false);
    _container = ProviderContainer(
      parent: parent,
      overrides: widget.overrides,
      adapters: widget.adapters,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: widget.child,
    );
  }
}

class UncontrolledProviderScope extends InheritedWidget {
  final ProviderContainer container;

  UncontrolledProviderScope({
    required this.container,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant UncontrolledProviderScope oldWidget) {
    return container != oldWidget.container;
  }

  static ProviderContainer? _of(BuildContext context, {required bool listen}) {
    final scope = (listen
            ? context.dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()
            : context.getElementForInheritedWidgetOfExactType<UncontrolledProviderScope>()?.widget)
        as UncontrolledProviderScope?;

    return scope?.container;
  }

  static ProviderContainer of(BuildContext context, {bool listen = false}) {
    final container = _of(context, listen: listen);
    if (container == null) {
      throw Exception("ProviderScope is not present in widget tree");
    }

    return container;
  }
}

extension ProviderContextExtension<T> on ProviderBase<T> {
  T of(BuildContext context, {bool listen = false}) {
    return UncontrolledProviderScope.of(context, listen: listen).read(this);
  }
}

extension ContextExtension on BuildContext {
  T dependOn<T>(ProviderBase<T> provider) {
    return UncontrolledProviderScope.of(this, listen: true).read(provider);
  }
}
