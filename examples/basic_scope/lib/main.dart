import 'package:flutter/material.dart';
import 'package:vessel_flutter/vessel_flutter.dart';
import 'package:scoping/utils.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CounterApp(),
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
              overrides: [counterProvider.scope()],
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
