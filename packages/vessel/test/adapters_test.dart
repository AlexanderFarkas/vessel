import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:vessel/src/internal_api.dart';

class ViewModel {
  int disposeCount = 0;
  dispose() {
    disposeCount++;
  }
}

class ViewModelAdapter extends ProviderAdapter<ViewModel> {
  @override
  void dispose(ViewModel providerValue) {
    providerValue.dispose();
  }
}

final viewModelProvider = Provider((read) => ViewModel());

void main() {
  test("Dispose is not called without adapter", () {
    final container = ProviderContainer();
    final viewModel = container.read(viewModelProvider);

    container.dispose();
    expect(viewModel.disposeCount, equals(0));
  });

  test("Dispose is called once with adapter", () {
    final container = ProviderContainer(
      adapters: [ViewModelAdapter()],
    );
    final viewModel = container.read(viewModelProvider);

    container.dispose();
    expect(viewModel.disposeCount, equals(1));
  });

  test("Own dispose has highest priority", () {
    final viewModelProvider = Provider((read) => ViewModel(), dispose: (vm) {
      vm.disposeCount += 3;
    });

    final container = ProviderContainer(adapters: [ViewModelAdapter()]);
    final viewModel = container.read(viewModelProvider);

    container.dispose();
    expect(viewModel.disposeCount, equals(3));
  });

  test("Dispose is called once, even if 2 compatible adapters are present", () {
    final container = ProviderContainer(
      adapters: [ViewModelAdapter(), ViewModelAdapter()],
    );
    final viewModel = container.read(viewModelProvider);

    container.dispose();
    expect(viewModel.disposeCount, equals(1));
  });
}
