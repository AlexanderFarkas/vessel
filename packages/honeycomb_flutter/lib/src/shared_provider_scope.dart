// ignore_for_file: invalid_use_of_internal_member

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';
import 'package:meta/meta.dart';

@internal
class SharedProviderScope extends StatefulWidget {
  final String id;
  final List<MaybeScoped> scoped;
  final Widget child;
  const SharedProviderScope({
    super.key,
    required this.id,
    required this.scoped,
    required this.child,
  });

  @override
  State<SharedProviderScope> createState() => _SharedProviderScopeState();
}

class _SharedProviderScopeState extends State<SharedProviderScope> {
  late final ProviderContainer _container;

  static final _storage = <String, SharedState>{};

  @override
  void initState() {
    super.initState();
    final parent = UncontrolledProviderScope.of(context);

    final state = _storage.putIfAbsent(widget.id, () => SharedState.initial(widget.scoped));
    assert(
      DeepCollectionEquality.unordered().equals(state.debugScoped, widget.scoped),
      "`scoped` parameter should be the same in every ProviderScope.shared with same id",
    );

    state.containersCount++;

    _container = ProviderContainer.shared(
      widget.scoped,
      parent: parent,
      providables: state.providables,
      cachedIsScoped: state.cachedIsScoped,
    );
  }

  @override
  void dispose() {
    final state = _storage[widget.id]!;
    state.containersCount--;

    // if current container was the last one
    if (state.containersCount == 0) {
      _storage.remove(widget.id);
      _container.disposeProvidables();
    }

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

class SharedState {
  int containersCount;
  final Map<MaybeScoped, bool> cachedIsScoped;
  final Map<ProviderBase, dynamic> providables;
  final List<MaybeScoped> debugScoped;

  SharedState({
    required this.containersCount,
    required this.cachedIsScoped,
    required this.providables,
    required this.debugScoped,
  });

  factory SharedState.initial(List<MaybeScoped> scoped) => SharedState(
        containersCount: 0,
        cachedIsScoped: {},
        providables: {},
        debugScoped: scoped,
      );
}
