import 'package:_common/_common.dart';
import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

void main() {
  runApp(
    ProviderScope.root(
      child: const CounterApp(),
    ),
  );
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

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CountText(),
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
            const Incrementer(
              title: "Global",
            ),
            ProviderScope(
              scoped: [counterProvider],
              child: const Incrementer(
                title: 'Scoped',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
