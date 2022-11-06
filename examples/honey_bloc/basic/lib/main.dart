import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

import 'package:honey_bloc/honey_bloc.dart';

final counterCubitProvider = BlocProvider.factory<CounterCubit, int, int>(
  (_, initialValue) => CounterCubit(initialValue),
);

class CounterCubit extends Cubit<int> {
  CounterCubit(super.initialState);

  void increment() {
    return emit(state + 1);
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final factoriedCubitProvider = counterCubitProvider(20);
    return MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: MultiBlocListener(
            listeners: [
              factoriedCubitProvider.listener(
                listenWhen: (previous, current) {
                  print("Prev: $previous, Curr: $current");
                  return current % 2 == 0;
                },
                listener: (context, state) => print(state),
              ),
            ],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                factoriedCubitProvider.builder(
                  builder: (context, state) => Text("Count: $state"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => factoriedCubitProvider.of(context).increment(),
                  child: const Text("Increment"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  return runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
