import 'package:comparison/override.dart';
import 'package:comparison/read.dart';
import 'package:comparison/register.dart';

void main(List<String> arguments) async {
  titlePrint("Register phase");

  namePrint("vessel");
  // no actions for vessel required

  namePrint("get_it");
  getItSetup();

  titlePrint("Read phase");

  namePrint("vessel");
  readvessel();

  namePrint("get_it");
  readGetIt();

  titlePrint("Override phase");
  namePrint("vessel");
  overridevessel();
  namePrint("get_it");
  overrideGetIt();
}

void titlePrint(String title) {
  print("-" * 10 + title + "-" * 10);
}

void namePrint(String name) {
  print("*" * 5 + name + "*" * 5);
}
