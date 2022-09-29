import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:honey_bloc/honey_bloc.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

typedef CubitProvider = BlocBindingMixin<Cubit<ThemeData>, ThemeData>;

final p = BlocProvider<ThemeCubit, ThemeData>((_) => ThemeCubit());
class MyThemeApp extends StatefulWidget {
  MyThemeApp({
    Key? key,
    required CubitProvider themeCubit,
    required Function onBuild,
  })  : _themeCubit = themeCubit,
        _onBuild = onBuild,
        super(key: key);

  final CubitProvider _themeCubit;
  final Function _onBuild;

  @override
  State<MyThemeApp> createState() => MyThemeAppState(
        themeCubit: _themeCubit,
        onBuild: _onBuild,
      );
}

class MyThemeAppState extends State<MyThemeApp> {
  MyThemeAppState({
    required CubitProvider themeCubit,
    required Function onBuild,
  })  : _themeCubitProvider = themeCubit,
        _onBuild = onBuild;

  CubitProvider _themeCubitProvider;
  final Function _onBuild;

  @override
  Widget build(BuildContext context) {
    return ProviderScope.root(
      child: _themeCubitProvider.Builder(
        builder: ((context, theme) {
          _onBuild();
          return MaterialApp(
            key: const Key('material_app'),
            theme: theme,
            home: Column(
              children: [
                ElevatedButton(
                  key: const Key('raised_button_1'),
                  child: const SizedBox(),
                  onPressed: () {
                    setState(() => _themeCubitProvider = BlocProvider((_) => DarkThemeCubit()));
                  },
                ),
                ElevatedButton(
                  key: const Key('raised_button_2'),
                  child: const SizedBox(),
                  onPressed: () {
                    setState(() => _themeCubitProvider = _themeCubitProvider);
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(ThemeData.light());

  void setDarkTheme() => emit(ThemeData.dark());
  void setLightTheme() => emit(ThemeData.light());
}

class DarkThemeCubit extends Cubit<ThemeData> {
  DarkThemeCubit() : super(ThemeData.dark());

  void setDarkTheme() => emit(ThemeData.dark());
  void setLightTheme() => emit(ThemeData.light());
}

class MyCounterApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyCounterAppState();
}

final counterCubitProvider = BlocProvider((_) => CounterCubit());

class MyCounterAppState extends State<MyCounterApp> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope.root(
      child: Builder(builder: (context) {
        return MaterialApp(
          home: Scaffold(
            key: const Key('myCounterApp'),
            body: Column(
              children: <Widget>[
                BlocBuilder<CounterCubit, int>(
                  provider: counterCubitProvider,
                  buildWhen: (previousState, state) {
                    return (previousState + state) % 3 == 0;
                  },
                  builder: (context, count) {
                    return Text(
                      '$count',
                      key: const Key('myCounterAppTextCondition'),
                    );
                  },
                ),
                BlocBuilder<CounterCubit, int>(
                  provider: counterCubitProvider,
                  builder: (context, count) {
                    return Text(
                      '$count',
                      key: const Key('myCounterAppText'),
                    );
                  },
                ),
                ElevatedButton(
                  key: const Key('myCounterAppIncrementButton'),
                  child: const SizedBox(),
                  onPressed: () => counterCubitProvider.of(context).increment(),
                )
              ],
            ),
          ),
        );
      }),
    );
  }
}

class CounterCubit extends Cubit<int> {
  CounterCubit({int seed = 0}) : super(seed);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

void main() {
  group('BlocBuilder', () {
    testWidgets('passes initial state to widget', (tester) async {
      final themeCubit = ThemeCubit();
      final themeCubitProvider = BlocProvider<ThemeCubit, ThemeData>((_) => themeCubit);

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubitProvider, onBuild: () => numBuilds++),
      );

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);
    });

    testWidgets('receives events and sends state updates to widget', (tester) async {
      final themeCubit = ThemeCubit();
      final themeCubitProvider = BlocProvider<ThemeCubit, ThemeData>((_) => themeCubit);
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubitProvider, onBuild: () => numBuilds++),
      );

      themeCubit.setDarkTheme();

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets('infers the cubit from the context if the cubit is not provided', (tester) async {
      final themeCubit = ThemeCubit();
      final themeCubitProvider = BlocProvider<ThemeCubit, ThemeData>((_) => themeCubit);
      var numBuilds = 0;
      await tester.pumpWidget(
        ProviderScope.root(
          child: themeCubitProvider.Builder(
            builder: (context, theme) {
              numBuilds++;
              return MaterialApp(
                key: const Key('material_app'),
                theme: theme,
                home: const SizedBox(),
              );
            },
          ),
        ),
      );

      themeCubit.setDarkTheme();

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();

      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets('updates cubit and performs new lookup when widget is updated', (tester) async {
      final themeCubit = ThemeCubit();
      final themeCubitProvider = BlocProvider((_) => themeCubit);
      var numBuilds = 0;
      await tester.pumpWidget(
        ProviderScope.root(
          child: StatefulBuilder(
            builder: (context, setState) => themeCubitProvider.Builder(
              builder: (context, theme) {
                numBuilds++;
                return MaterialApp(
                  key: const Key('material_app'),
                  theme: theme,
                  home: ElevatedButton(
                    child: const SizedBox(),
                    onPressed: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 2);
    });

    testWidgets(
        'updates when the cubit is changed at runtime to a different cubit and '
        'unsubscribes from old cubit', (tester) async {
      final themeCubit = ThemeCubit();
      final themeCubitProvider = BlocProvider<ThemeCubit, ThemeData>((_) => themeCubit);

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubitProvider, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(const Key('raised_button_1')));
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets(
        'does not update when the cubit is changed at runtime to same cubit '
        'and stays subscribed to current cubit', (tester) async {
      final themeCubit = DarkThemeCubit();
      final themeCubitProvider = BlocProvider<DarkThemeCubit, ThemeData>((_) => themeCubit);
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubitProvider, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(const Key('raised_button_2')));
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets('shows latest state instead of initial state', (tester) async {
      final themeCubit = ThemeCubit()..setDarkTheme();
      final themeCubitProvider = BlocProvider<ThemeCubit, ThemeData>((_) => themeCubit);

      await tester.pumpAndSettle();

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubitProvider, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);
    });

    testWidgets('with buildWhen only rebuilds when buildWhen evaluates to true', (tester) async {
      await tester.pumpWidget(MyCounterApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('myCounterApp')), findsOneWidget);

      final incrementButtonFinder = find.byKey(const Key('myCounterAppIncrementButton'));
      expect(incrementButtonFinder, findsOneWidget);

      final counterText1 = tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText1.data, '0');

      final conditionalCounterText1 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText1.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText2 = tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText2.data, '1');

      final conditionalCounterText2 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText2.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText3 = tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText3.data, '2');

      final conditionalCounterText3 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText3.data, '2');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText4 = tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText4.data, '3');

      final conditionalCounterText4 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText4.data, '2');
    });

    testWidgets('calls buildWhen and builder with correct state', (tester) async {
      final buildWhenPreviousState = <int>[];
      final buildWhenCurrentState = <int>[];
      final states = <int>[];
      final counterCubit = CounterCubit();
      final counterCubitProvider = BlocProvider((_) => counterCubit);
      await tester.pumpWidget(
        ProviderScope.root(
          child: counterCubitProvider.Builder(
            buildWhen: (previous, state) {
              if (state % 2 == 0) {
                buildWhenPreviousState.add(previous);
                buildWhenCurrentState.add(state);
                return true;
              }
              return false;
            },
            builder: (_, state) {
              states.add(state);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      counterCubit
        ..increment()
        ..increment()
        ..increment();
      await tester.pumpAndSettle();

      expect(states, [0, 2]);
      expect(buildWhenPreviousState, [1]);
      expect(buildWhenCurrentState, [2]);
    });

    testWidgets(
        'does not rebuild with latest state when '
        'buildWhen is false and widget is updated', (tester) async {
      const key = Key('__target__');
      final states = <int>[];
      final counterCubit = CounterCubit();
      final counterCubitProvider = BlocProvider((_) => counterCubit);
      await tester.pumpWidget(
        ProviderScope.root(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) => counterCubitProvider.Builder(
                buildWhen: (previous, state) => state % 2 == 0,
                builder: (_, state) {
                  states.add(state);
                  return ElevatedButton(
                    key: key,
                    child: const SizedBox(),
                    onPressed: () => setState(() {}),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      counterCubit
        ..increment()
        ..increment()
        ..increment();
      await tester.pumpAndSettle();
      expect(states, [0, 2]);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(states, [0, 2, 2]);
    });

    testWidgets('rebuilds when provided bloc is changed', (tester) async {
      final firstCounterCubit = CounterCubit();
      final firstCounterCubitProvider = BlocProvider((_) => firstCounterCubit);
      final secondCounterCubit = CounterCubit(seed: 100);
      final secondCounterCubitProvider = BlocProvider((_) => secondCounterCubit);

      await tester.pumpWidget(
        ProviderScope.root(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: firstCounterCubitProvider.Builder(
              builder: (context, state) => Text('Count $state'),
            ),
          ),
        ),
      );

      expect(find.text('Count 0'), findsOneWidget);

      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
      expect(find.text('Count 0'), findsNothing);

      await tester.pumpWidget(
        ProviderScope.root(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: secondCounterCubitProvider.Builder(
              builder: (context, state) => Text('Count $state'),
            ),
          ),
        ),
      );

      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 1'), findsNothing);

      secondCounterCubit.increment();
      await tester.pumpAndSettle();

      expect(find.text('Count 101'), findsOneWidget);
    });
  });
}
