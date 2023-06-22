import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/game/scenario/bottom_message.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/scenario_object.dart';

typedef ScenarioCallbackFunction = void Function(
    ScenarioObject scenario, ActorMixin actor, MyGame game);

class ScenarioFunctionsRegistry {
  ScenarioFunctionsRegistry(this.game);

  final MyGame game;

  final Map<String, ScenarioCallbackFunction> _functionsRegistry = {
    'listenEnteringTheTank': (scenario, actor, game) {
      if (actor.data.factions.contains(Faction(name: 'Player'))) {
        final text = scenario.text;
        if (text.isNotEmpty) {
          game.showScenarioMessage(TalkDialog(
            says: [
              Say(
                text: [TextSpan(text: scenario.text)],
              ),
            ],
          ));
        }
      } else {
        final behavior = actor.findBehavior<InteractionSetPlayer>();
        behavior.action = () {
          game.hideScenarioMessage();
          scenario.removeFromParent();
          behavior.action = null;
        };
      }
    },
    'showMessage': (scenario, actor, game) {
      final text = scenario.text;
      if (text.isNotEmpty) {
        game.showScenarioMessage(TalkDialog(
          // nextOnTap: true,
          // nextOnAnyKey: true,
          says: [
            Say(
              text: [TextSpan(text: scenario.text)],
            ),
          ],
        ));
      }
    },
    'hideMessageNoRemove': (scenario, actor, game) {
      game.hideScenarioMessage();
    },
    'hideMessage': (scenario, actor, game) {
      game.hideScenarioMessage();
      scenario.removeFromParent();
    },
  };

  void addFunction(String name, ScenarioCallbackFunction callback) {
    _functionsRegistry[name] = callback;
  }

  ScenarioCallbackFunction? getFunction(String name) =>
      _functionsRegistry[name];
}
