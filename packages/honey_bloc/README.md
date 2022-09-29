honeycomb_flutter wrapper for [bloc](https://github.com/felangel/bloc) package

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


## Listen for changes

```dart
final counterCubitProvider = BlocProvider<CounterCubit, int>(
    (_) => CounterCubit(),
);

...

Widget build(BuildContext context) {
    return counterCubitProvider.Listener(
        listener: (context, state) {
            print("Counter: $state")
        },
        child: Text(...),
    );
}
```

### Several listeners:
```dart
Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
            counterCubitProvider.Listener(
                listener: (context, state) {
                    print("Counter: $state")
                },
            ),
            themeCubitProvider.Listener(
                listener: (context, state) {
                    print("Theme: $state")
                },
            ),
        ],
        child: Text(...),
    );
}
```

### Filter states
If we want to trigger listener only when `counter`'s state is even:
```dart
counterCubitProvider.Listener(
    listenWhen: (previousState, currentState) => currentState % 2 == 0,
    listener: (context, state) {
        print("Counter: $state")
    },
),
```

## Consumer - combine Builder and Listener into single widget
```dart
counterCubitProvider.Consumer(
    listenWhen: (previousState, currentState) => currentState % 2 == 0,
    listener: (context, state) {
        print("Counter: $state")
    },
    buildWhen: (_, currentState) => currentState % 2 != 0,
    builder: (context, state) => Text("Only odd count: $state"),
)
```

## How to define Repositories?

You could use `honeycomb`'s `Provider` for that:
```dart
final userRepositoryProvider = Provider((_) => UserRepository());

final userProfileCubitProvider = BlocProvider.factory<UserProfileCubit, User, int>(
    (read, int userId) => UserProfileCubit(
        userId: userId,
        repository: read(userRepositoryProvider),
    ),
);

...

Widget builder(BuildContext context) {
    return userProfileCubitProvider(1).Builder(
        builder: (context, state) => Text("username: ${state.name}"),
    );
} 
```

## How to scope, dispose and override cubits?
Check out [`honeycomb_flutter`](https://github.com/AlexanderFarkas/honeycomb/tree/master/packages/honeycomb_flutter) documentation
