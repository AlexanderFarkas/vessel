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
void main() => runApp(
    // For widgets to be able to read providers, we need to wrap the entire
    // application in a "ProviderScope.root" widget.
    ProviderScope(
        child: CounterApp(),
    ),
);
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
      body: counterCubitProvider.builder(
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
    return counterCubitProvider.listener(
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
            counterCubitProvider.listener(
                listener: (context, state) {
                    print("Counter: $state")
                },
            ),
            themeCubitProvider.listener(
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
counterCubitProvider.listener(
    listenWhen: (previousState, currentState) => currentState % 2 == 0,
    listener: (context, state) {
        print("Counter: $state")
    },
),
```

## Consumer - combine `builder` and `listener` into single widget
```dart
counterCubitProvider.consumer(
    listenWhen: (previousState, currentState) => currentState % 2 == 0,
    listener: (context, state) {
        print("Counter: $state")
    },
    buildWhen: (_, currentState) => currentState % 2 != 0,
    builder: (context, state) => Text("Only odd count: $state"),
)
```

## Selector
`selector` is analogous to `builder` but allows developers to filter updates by selecting a new value based on the current bloc state. Unnecessary builds are prevented if the selected value does not change. The selected value must be immutable in order for `selector` to accurately determine whether builder should be called again.

```dart
counterCubitProvider.selector<bool>(
    selector: (context, state) => state % 2 == 0,
    builder: (context, state) => Text("isEven: $state"),
)
```

## Widgets 
Every provider's method has it's Widget counterpart:
* `.builder` -> `BlocBuilder<Bloc, State>`
* `.listener` -> `BlocListener<Bloc, State>`
* `.consumer` -> `BlocConsumer<Bloc, State>`
* `.selector<SelectedState>` -> `BlocSelector<Bloc, State, SelectedState>`

which are more suitable, if you want to define your bloc outside of `honeycomb`

Example
```dart
class _MyAppState extends State<MyApp> {
  final bloc = MyBloc();

  void dispose() {
    bloc.close();
    super.dispose();
  }

  Widget build(BuildContext context) => BlocBuilder<MyBloc, MyState>(
    bloc: bloc,
    builder: (context, state) => // build widget tree based on state
  );
}
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
    return userProfileCubitProvider(1).builder(
        builder: (context, state) => Text("username: ${state.name}"),
    );
} 
```

## How to scope, dispose and override cubits?
Check out [`honeycomb_flutter`](https://github.com/AlexanderFarkas/honeycomb/tree/master/packages/honeycomb_flutter) documentation

## Credits 
Credits to [Felix Angelov](https://github.com/felangel) for creating such an amazing package.
Also, I've taken several documentation pieces from [flutter_bloc](https://pub.dev/packages/flutter_bloc)