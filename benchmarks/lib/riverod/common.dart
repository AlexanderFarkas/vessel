import 'package:riverpod/riverpod.dart';

const int _kNumWarmUp = 1000;

warmUp() {
  for (var i = 0; i < _kNumWarmUp; i += 1) {
    final container = ProviderContainer();
    final providers = List.generate(500, (index) => Provider((ref) => index));
    providers.forEach(container.read);
  }
}
