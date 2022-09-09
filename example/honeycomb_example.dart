import 'package:honeycomb/honeycomb.dart';

final defaultMaxHealthProvider = Provider((_) => 100);
final bossRoomMaxHealthProvider = Provider((read) => read(defaultMaxHealthProvider) ~/ 2);

void main(List<String> args) {
  final container = Container();
  container.read(defaultMaxHealthProvider); // 100

  final bossRoomContainer = Container(
    parent: container,
    overrides: [defaultMaxHealthProvider.overrideWith(bossRoomMaxHealthProvider)],
  );
  bossRoomContainer.read(bossRoomMaxHealthProvider); // 50
}
