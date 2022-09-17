import 'package:flutter/material.dart';
import 'package:honeycomb_flutter/honeycomb_flutter.dart';


void main() {
  return runApp(
    ProviderScope.root(
      child: Text("Hello, world"),
    ),
  );
}
