Honeycomb for Flutter

For more information about DI itself see (honeycomb)[https://github.com/AlexanderFarkas/honeycomb/tree/master/packages/honeycomb]

## Features

- Inject your providers via context
- [Coming Soon] Share scoped providers across multiple routes

## Getting started

```dart
final counterProvider = Provider((_) => ValueNotifier<int>(0));

void main() {
  runApp(
    ProviderScope.root(
      child: App(),
    )
  );
}

class App extends StatelessWidget {
  Widget build(BuildContext) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: counterProvider.of(context, listen: true),
          builder: (_, value, __) => Text("Count: $value"),
        ),
        OutlinedButton(
          onPressed: () {
            counterProvider.of(context).value++;
          },
          child: Text("Increment"),
        )
      ]
    );
  }
}
```

## Usage

### How to read a provider?
If you're reading a provider inside build method, use:
```dart
myProvider.of(context, listen: true); 
```

Remark: *You wouldn't need `listen: true` very often.
You should either use `honeybloc` package or write your own wrapper, depending on state management you use.*

In most cases (lifecycle method, callbacks) you should use it like:
```
myProvider.of(context);
```



### Scoping

You could introduce scopes to create and dispose your providers together with its widget trees.

```dart
final counterProvider = Provider(
  (_) => ValueNotifier<int>(0),
  dispose: (vn) {
    vn.dispose();
    print("Dispose");
  },
);


class App extends StatelessWidget {
  Widget build(BuildContext) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: counterProvider.of(context, listen: true),
          builder: (_, value, __) => Text("Count: $value"),
        ),
        OutlinedButton(
          onPressed: () {
            counterProvider.of(context).value++;
          },
          child: Text("Increment"),
        )
      ]
    );
  }
}

class SecondPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return ProviderScope(
      scoped: [counterProvider],
      child: Builder(
        builder: (context) => Column(
          children: [
            ValueListenableBuilder(
              valueListenable: counterProvider.of(
                context, 
                listen: true,
              ),
              builder: (_, value, __) => Text("Count: $value"),
            ),
            OutlinedButton(
              onPressed: () {
                counterProvider.of(context).value++;
              },
              child: Text("Increment"),
            )
          ]
        )
      )
    );
  }
}
```

Now, everytime you pop and push `SecondPage` its counter will be recreated. Also you will see "Dispose" in console.

Global counter will remain unctouched.

To test it yourself see [scoping example](https://github.com/AlexanderFarkas/honeycomb/tree/master/examples/scoping)

