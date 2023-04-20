import 'package:flutter/material.dart';
import 'package:vessel_flutter/vessel_flutter.dart';

import 'package:vessel_bloc/vessel_bloc.dart';

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
              counterCubitProvider.builder(
                builder: (context, state) => Text("Count: $state"),
              ),
              SizedBox(height: 10),
              OutlinedButton(
                onPressed: counterCubitProvider.of(context, listen: true).increment,
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
    ProviderScope(child: App()),
  );
}
