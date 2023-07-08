import 'package:flutter/material.dart';
import 'package:tank_game/ui/game/scenario/bottom_message.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
import 'package:tank_game/world/core/scenario/scenario_description.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';
import 'package:tank_game/world/environment/spawn/spawn_behavior.dart';

class DemoScenario extends Scenario {
  DemoScenario({super.name = 'Demo', super.description = 'Not just test map!'});

  @override
  String? get worldFile => 'demo.world';

  @override
  void onLoad() {
    super.onLoad();
    AreaInitScriptComponent.registerType('TutorialUseFirstTank',
        (lifetimeMax, creator) => TutorialUseFirstTank(creator.text));

    game.world.scenarioLayer.add(TrackTankCreation());
  }
}

class TutorialUseFirstTank extends ScriptCore {
  final String text;

  TutorialUseFirstTank(this.text);

  @override
  void onStreamMessage(ScenarioEvent<dynamic> message) {
    if (message is EventSetPlayer) {
      game.showScenarioMessage(TalkDialog(
        // nextOnTap: true,
        // nextOnAnyKey: true,
        says: [
          Say(
            text: [TextSpan(text: text)],
          ),
        ],
      ));
      removeFromParent();
      game.world.scenarioLayer.children
          .whereType<TrackTankCreation>()
          .forEach(game.world.scenarioLayer.remove);
    }
  }

  @override
  void scriptUpdate(double dt) {
    // TODO: implement scriptUpdate
  }
}

class TrackTankCreation extends ScriptCore {
  @override
  void onStreamMessage(ScenarioEvent message) {
    if (message is EventSpawned) {
      final actor = message.data;
      if (actor is TankEntity &&
          actor.data.factions.contains(Faction(name: 'Neutral'))) {
        actor.loaded.then((_) {
          try {
            actor.findBehavior<InteractionSetPlayer>().onComplete = (_) {
              actor.scenarioEvent(
                  EventSetPlayer(emitter: actor, name: 'TutorialPlayerSet'));
            };
          } catch (_) {}
        });
      }
    }
  }

  @override
  void scriptUpdate(double dt) {
    // TODO: implement scriptUpdate
  }
}
