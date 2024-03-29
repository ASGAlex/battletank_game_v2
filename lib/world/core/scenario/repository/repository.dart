import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/repository/tutorial.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/core/scenario/scenario_description.dart';

class ScenarioRepository {
  final scenarios = <Scenario>[];
  final sharedFunctions = <String, ScenarioCallbackFunction>{
    'showMessage': _showMessage
  };

  initMissionList() {
    // scenarios.add(DemoScenario());
    scenarios.add(TutorialScenario());
    // scenarios.add(CellTestScenario());
  }
}

void _showMessage(
    ScenarioComponentCore scenario, ActorMixin actor, MyGame game) {}
