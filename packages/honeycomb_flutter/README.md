Honeycomb for Flutter

For more information about DI itself see [honeycomb](https://github.com/AlexanderFarkas/honeycomb/tree/master/packages/honeycomb)

## Getting started

Wrap your app in `ProviderScope` widget:
```dart
void main() {
  runApp(
    ProviderScope(child: App())
  );
}
```

Read your providers with `of` extension method:
```dart
GestureDetector(
  onTap: () => myProvider.of(context).doSomething()
  child: ...
);
```

Each `ProviderScope` introduces new `ProviderContainer`, which becomes child of the previous container.
When `ProviderScope` widget disposes, it disposes `ProviderContainer` with it.

## Overriding and scoping

It's possible to override provider with another one:
```dart
ProviderScope(
  overrides: [
    myProvider.overrideWith(anotherProvider),
  ],
  child: ...
)
```

Or just scope it:
```dart
ProviderScope(
  overrides: [
    myProvider.scope(),
  ],
  child: ...
)
```

## Pass parent

`ProviderScope` takes its parent from the `BuildContext`. But you could override it with `parent` constructor parameter. 

It could be useful with dialogs:
```dart
ProviderScope(
  overrides: [myVmProvider.scoped()]
  child: Builder(
    builder: (context) => GestureDetector(
      onTap: () {
        final container = UncontrolledProviderScope.of(context);
        showAlertDialog(
          builder: (context) => ProviderScope(
            parent: container,
            child: ...
          )
        )
      }, 
      child: ...
    )
  )
)
```

Now your dialog will receive all scoped providers from the parent screen. 



