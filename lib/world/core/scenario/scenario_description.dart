import 'package:tank_game/world/core/scenario/scenario_component.dart';

class Scenario {
  Scenario(
      {required this.name,
      required this.description,
      this.mapFile,
      this.worldFile});

  String name;
  String description;
  String? mapFile;
  String? worldFile;

  List<String> objectives = [];

  final customScenarioTypes = <String, ScenarioTypeFactory>{};

  final customFunctions = <String, ScenarioCallbackFunction>{};

  void init() {
    ScenarioComponent.restoreDefaults();
  }
}
