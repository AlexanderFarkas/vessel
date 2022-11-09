/// Support for doing something awesome.
///
/// More dartdocs go here.
library _common;

import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';

final counterProvider = Provider(
  (_) => ValueNotifier(0),
  dispose: (state) {
    print("Dispose");
    state.dispose();
  },
);

class Incrementer extends StatelessWidget {
  final String title;
  const Incrementer({Key? key, required this.title}) : super(key: key);

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
        const CountText(),
        const SizedBox(height: 10),
        const IncrementButton(),
      ],
    );
  }
}

class CountText extends StatelessWidget {
  const CountText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: counterProvider.of(context, listen: true),
      builder: (_, value, __) => Text("Count: $value"),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => counterProvider.of(context).value++,
      child: const Text("Increment"),
    );
  }
}
