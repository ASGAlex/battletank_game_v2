import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
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

  MyGame get game => SettingsController().currentGame!;

  @mustCallSuper
  void onLoad() {
    ScenarioComponent.restoreDefaults();
    AreaInitScriptComponent.restoreDefaults();
  }
}
