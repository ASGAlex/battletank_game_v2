import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/scenario_object.dart';

typedef ScenarioCallbackFunction = void Function(
    ScenarioObject scenario, ActorMixin actor);

class ScenarioFunctionsRegistry {
  final Map<String, ScenarioCallbackFunction> _functionsRegistry = {
    'listenEnteringTheTank': (scenario, actor) {
      print('callback listenEnteringTheTank!');
    },
    'showMessage': (scenario, actor) {
      print('callback showMessage!');
    },
    'hideMessage': (scenario, actor) {
      print('callback hideMessage!');
      scenario.removeFromParent();
    },
  };

  void addFunction(String name, ScenarioCallbackFunction callback) {
    _functionsRegistry[name] = callback;
  }

  ScenarioCallbackFunction? getFunction(String name) =>
      _functionsRegistry[name];
}
