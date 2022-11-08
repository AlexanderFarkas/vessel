import 'package:comparison/override.dart';
import 'package:comparison/read.dart';
import 'package:comparison/register.dart';

void main(List<String> arguments) async {
  titlePrint("Register phase");

  namePrint("honeycomb");
  // no actions for honeycomb required

  namePrint("get_it");
  getItSetup();

  titlePrint("Read phase");

  namePrint("honeycomb");
  readHoneycomb();

  namePrint("get_it");
  readGetIt();

  titlePrint("Override phase");
  namePrint("honeycomb");
  overrideHoneycomb();
  namePrint("get_it");
  overrideGetIt();
}

void titlePrint(String title) {
  print("-" * 10 + title + "-" * 10);
}

void namePrint(String name) {
  print("*" * 5 + name + "*" * 5);
}
