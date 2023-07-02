import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/functions_registry.dart';
import 'package:tank_game/world/core/scenario/scenario_object.dart';

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
  final Map<String, ScenarioCallbackFunction> functions = {};
}

class ScenarioRepository {
  final scenarios = <Scenario>[];

  initMissionList() {
    // const mapFiles = <String, String>{
    //   'collisiontest.tmx': 'Small to test collisions',
    //   // 'mission.tmx': 'Real mission on relatively big map',
    //   'performance_test.tmx': 'Boring but very big map for performance testing'
    // };
    // mapFiles.forEach((key, value) {
    //   missions.add(Scenario(
    //       name: key.replaceAll('.tmx', ''), description: value, mapFile: key));
    // });

    scenarios.add(DemoScenario());
    scenarios.add(CellTestScenario());
  }
}

class CellTestScenario extends Scenario {
  CellTestScenario(
      {super.name = 'Cell Test', super.description = 'Not just test map!'});

  @override
  String? get mapFile => 'cell_test.tmx';
}

class DemoScenario extends Scenario {
  DemoScenario({super.name = 'Demo', super.description = 'Not just test map!'});

  @override
  String? get worldFile => 'demo.world';

  final Map<String, ScenarioCallbackFunction> functions = {
    'onFirstSpawn': onFirstSpawn,
  };

  static void onFirstSpawn(
      ScenarioObject scenario, ActorMixin actor, MyGame game) {}
}
