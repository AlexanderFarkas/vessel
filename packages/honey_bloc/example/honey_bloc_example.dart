import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

import 'package:honey_bloc/honey_bloc.dart';

final counterCubitProvider = BlocProvider<CounterCubit, int>((_) => CounterCubit(0));

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
    return MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              counterCubitProvider.Builder(
                builder: (context, state) => Text("Count: $state"),
              ),
              SizedBox(height: 10),
              OutlinedButton(
                onPressed: context.watch(counterCubitProvider).increment,
                child: Text("Increment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  return runApp(
    ProviderScope.root(
      child: App(),
    ),
  );
}
