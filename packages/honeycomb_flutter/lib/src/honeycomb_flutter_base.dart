import 'package:flutter/widgets.dart';

import 'package:honeycomb/honeycomb.dart';
import 'package:honeycomb_flutter/src/shared_provider_scope.dart';

class ProviderScope extends StatefulWidget {
  final List<MaybeScoped> scoped;
  final Widget child;
  const ProviderScope({
    Key? key,
    required this.scoped,
    required this.child,
  }) : super(key: key);

  static root({
    List<Override> overrides = const [],
    required Widget child,
  }) {
    return _RootProviderScope(
      overrides: overrides,
      child: child,
    );
  }

  static shared({
    required String id,
    required List<MaybeScoped> scoped,
    required Widget child,
  }) {
    return SharedProviderScope(
      id: id,
      scoped: scoped,
      child: child,
    );
  }

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    final parent = UncontrolledProviderScope.of(context);
    _container = ProviderContainer.scoped(widget.scoped, parent: parent);
  }

  @override
  void dispose() {
    _container.disposeProvidables();
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

  static ProviderContainer of(BuildContext context, {bool listen = false}) {
    final scope = (listen
            ? context.dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()
            : context.getElementForInheritedWidgetOfExactType<UncontrolledProviderScope>()?.widget)
        as UncontrolledProviderScope?;

    if (scope == null) {
      throw Exception("ProviderScope is not present in widget tree");
    }

    return scope.container;
  }
}

class _RootProviderScope extends StatefulWidget {
  final List<Override> overrides;
  final Widget child;
  const _RootProviderScope({
    Key? key,
    required this.overrides,
    required this.child,
  }) : super(key: key);

  @override
  State<_RootProviderScope> createState() => _RootProviderScopeState();
}

class _RootProviderScopeState extends State<_RootProviderScope> {
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderContainer.root(overrides: widget.overrides);
  }

  @override
  void dispose() {
    _container.disposeProvidables();
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

extension ContextProviderExtension<T> on ProviderBase<T> {
  // You should listen in your own state management wrappers.
  // E.g. in self-made BlocBuilder
  T of(BuildContext context, {bool listen = false}) {
    return UncontrolledProviderScope.of(context, listen: listen).read(this);
  }
}
