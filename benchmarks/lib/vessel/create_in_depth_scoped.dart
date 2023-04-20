import 'package:vessel/vessel.dart';

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
    depth: 50,
    watch: watch,
    printer: printer,
  );
  _benchmark(
    depth: 100,
    watch: watch,
    printer: printer,
  );
  _benchmark(
    depth: 200,
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
    final providers = <Provider<int>>[];
    for (int i = 0; i < depth; i++) {
      if (i == 0) {
        providers.add(Provider((_) => 1));
      } else {
        providers.add(Provider((read) => read(providers[i - 1]) + 1));
      }
    }

    final _container = ProviderContainer();
    final _container2 = ProviderContainer(overrides: [
      providers[40].scope(),
    ], parent: _container);
    final container = ProviderContainer(overrides: [], parent: _container2);

    watch.start();
    container.read(providers.last);
    watch.stop();
  }

  final elapsed = watch.elapsedMicroseconds;

  printer.addResult(
    description:
        'create provider with scoped transitive dependency and depth == $depth',
    value: elapsed * scale,
    unit: 'ns per iteration',
    name: 'create_scoped$depth',
  );
}
