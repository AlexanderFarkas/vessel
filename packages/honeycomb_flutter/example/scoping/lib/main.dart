import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

void main() {
  runApp(
    ProviderScope.root(
      child: const CounterApp(),
    ),
  );
}

class CounterViewModel extends ValueNotifier<int> {
  CounterViewModel() : super(0);

  void increment() {
    value++;
    notifyListeners();
  }
}

class CounterApp extends StatelessWidget {
  const CounterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

final counterProvider = Provider((_) => CounterViewModel(), dispose: (state) => state.dispose());

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _CountText(),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SecondPage(),
                ),
              ),
              child: const Text("Go to second page"),
            )
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox.expand(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _Incrementer(
              title: "Global",
            ),
            ProviderScope(
              scoped: [counterProvider],
              child: const _Incrementer(
                title: 'Scoped',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Incrementer extends StatelessWidget {
  final String title;
  const _Incrementer({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        const _CountText(),
        const SizedBox(height: 10),
        const _IncrementButton(),
      ],
    );
  }
}

class _CountText extends StatelessWidget {
  const _CountText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: counterProvider.of(context, listen: true),
      builder: (_, value, __) => Text("Count: $value"),
    );
  }
}

class _IncrementButton extends StatelessWidget {
  const _IncrementButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        counterProvider.of(context).increment();
      },
      child: const Text("Increment"),
    );
  }
}
