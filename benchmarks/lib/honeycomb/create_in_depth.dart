import 'package:honeycomb/honeycomb.dart';

import '../common.dart';
import 'common.dart';

const int _kNumIterations = 100000;

void main() {
  assert(
    false,
    "Don't run benchmarks in checked mode! Use 'dart run'.",
  );

  final printer = BenchmarkResultPrinter();
  final watch = Stopwatch();

  warmUp();

  watch.reset();
  _benchmark(
    depth: 5,
    watch: watch,
    printer: printer,
  );
  _benchmark(
    depth: 20,
    watch: watch,
    printer: printer,
  );
  _benchmark(
    depth: 40,
    watch: watch,
    printer: printer,
  );
  _benchmark(
    depth: 100,
    watch: watch,
    printer: printer,
  );

  printer.printToStdout();
}

void _benchmark({
  required Stopwatch watch,
  required int depth,
  required BenchmarkResultPrinter printer,
}) {
  const scale = 1000.0 / _kNumIterations;

  for (int i = 0; i < _kNumIterations; i++) {
    final container = ProviderContainer();
    final providers = [];
    for (int i = 0; i < depth; i++) {
      if (i == 0) {
        providers.add(Provider((_) => 1));
      } else {
        providers.add(Provider((read) => read(providers[i - 1]) + 1));
      }
    }
    watch.start();
    container.read(providers.last);
    watch.stop();
  }

  final elapsed = watch.elapsedMicroseconds;

  printer.addResult(
    description: 'create_indepth$depth',
    value: elapsed * scale,
    unit: 'ns per iteration',
    name: 'create_indepth$depth',
  );
}
