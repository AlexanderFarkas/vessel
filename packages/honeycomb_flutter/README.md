Honeycomb for Flutter

For more information about DI itself see [honeycomb](https://github.com/AlexanderFarkas/honeycomb/tree/master/packages/honeycomb)


### Navigation
- [Features](#features)
- [Getting started](#getting-started)
- [Usage](#usage)
  - [How to read a provider?](#how-to-read-a-provider)
  - [Scoping](#scoping)
  - [Sharing scope](#sharing-scope)
    - [When do shared providers dispose?](#when-do-shared-providers-dispose)
    - [Tip](#tip)

## Features

- Inject your providers via context
- Share scoped providers across multiple routes

## Getting started

```dart
final counterProvider = Provider((_) => ValueNotifier<int>(0));

void main() {
  runApp(
    // For widgets to be able to read providers, we need to wrap the entire
    // application in a "ProviderScope.root" widget.
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

### Sharing scope
You could share same scoped providers even if ther are located in different widget trees.

How it works with `ProviderScope`?
```dart
class IncrementButton extends StatelessWidget {
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => counterProvider.of(context).increment(),
      child: Text("Increment"),
    )
  }
}

Column(
  children: [
    ProviderScope(
      scoped: [counterProvider],
      child: IncrementButton(),
    ),
    ProviderScope(
      scoped: [counterProvider],
      child: IncrementButton(),
    )
  ]
)
```

Now, every time you click either button, it increments its own counter instance.

Let's make a small change:
```dart

Column(
  children: [
    ProviderScope.shared(
      id: 'counter',
      scoped: [counterProvider],
      child: IncrementButton(),
    ),
    ProviderScope.shared(
      id: 'counter',
      scoped: [counterProvider],
      child: IncrementButton(),
    )
  ]
)
```

Now each button increments the same counter!

Shared scopes are very useful, when you need to inject same scoped provider on multiple routes/dialogs

#### When do shared providers dispose?
When the last provider scope with particular `id`  is disposed.

#### Tip
It's better to extract your shared scope to a widget, so you could never mistype `scoped` or `id` parameters. Like that:

```dart
class SharedCounterScope extends StatelessWidget {
  final Widget child;

  SharedCounterScope({required this.child});

  Widget build(BuildContext context) {
    return  ProviderScope.shared(
      id: 'counter',
      scoped: [counterProvider],
      child: child,
    );
  }
}
```


