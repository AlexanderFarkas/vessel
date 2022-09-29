BLoC library for honeycomb

## Usage

Lets take a look at how to use `BlocProvider` to provide a `CounterCubit` to a `CounterPage` and react to state changes with `BlocBuilder`.

### counter_cubit.dart

```dart
final counterCubitProvider = BlocProvider<CounterCubit, int>((_) => CounterCubit());

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

### main.dart

```dart
void main() => runApp(ProviderScope.root(CounterApp()));
class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterPage(),
    );
  }
}
```

### counter_page.dart

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: counterCubitProvider.Builder(
        builder: (context, count) => Center(child: Text('$count')),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => counterCubitProvider.of(context).increment(),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () => counterCubitProvider.of(context).decrement(),
          ),
        ],
      ),
    );
  }
}
```
