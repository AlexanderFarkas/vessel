import 'package:_common/_common.dart';
import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

void main() {
  runApp(ProviderScope.root(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
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
            _PushScopedButton(),
          ],
        ),
      ),
    );
  }
}

class _PushScopedButton extends StatelessWidget {
  const _PushScopedButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ScopedPage(),
        ),
      ),
      child: const Text("Go to scoped page"),
    );
  }
}

class ScopedPage extends StatelessWidget {
  const ScopedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Incrementer(
                  title: "Global",
                ),
                ProviderScope.shared(
                  id: "counter",
                  scoped: [counterProvider],
                  child: const Incrementer(
                    title: 'Shared Scope',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _PushScopedButton(),
          ],
        ),
      ),
    );
  }
}
