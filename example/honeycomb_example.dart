
import 'package:honeycomb/honeycomb.dart';


final defaultMaxHealthProvider = Provider((_) => 100);

final maxHealthProvider = Provider((read) => read(defaultMaxHealthProvider));
final bossRoomMaxHealthProvider = Provider((read) => read(defaultMaxHealthProvider) ~/ 2);

void main(List<String> args) {
  final container = Container();
  print(container.read(defaultMaxHealthProvider)); // 100

  final bossRoomContainer = Container(
    parent: container,
    overrides: [maxHealthProvider.overrideWith(bossRoomMaxHealthProvider)],
  );
  
  print(bossRoomContainer.read(maxHealthProvider)); // 50
}
