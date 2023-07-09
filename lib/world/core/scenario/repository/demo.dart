import 'package:flutter/material.dart';
import 'package:tank_game/ui/game/scenario/bottom_message.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
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
        (lifetimeMax, creator) {
      return TutorialUseFirstTank(creator);
    });

    game.world.scenarioLayer.add(TrackTankCreation());
  }
}

class TutorialUseFirstTank extends ScriptCore {
  late final String textTaskToKill;
  late final String textTaskToKillSuccess;
  late final String textTaskToKillCounter;
  int killedTanks = 0;

  TutorialUseFirstTank(AreaInitScriptComponent initializer) {
    textTaskToKill = initializer.getTextMessage('textTaskToKill');
    textTaskToKillSuccess = initializer.getTextMessage('textTaskToKillSuccess');
    textTaskToKillCounter = initializer.getTextMessage('textTaskToKillCounter');
  }

  @override
  void onStreamMessage(ScenarioEvent<dynamic> message) {
    if (message is EventSetPlayer) {
      game.showScenarioMessage(TalkDialog(
        // nextOnTap: true,
        // nextOnAnyKey: true,
        says: [
          Say(
            text: [TextSpan(text: textTaskToKill)],
          ),
        ],
        key: UniqueKey(),
      ));
    } else if (message is EventKilled) {
      if (message.emitter != game.currentPlayer &&
          message.emitter is TankEntity &&
          (message.emitter as TankEntity).data.coreState !=
              ActorCoreState.wreck) {
        var text = textTaskToKillSuccess;
        killedTanks++;
        if (killedTanks > 1) {
          text = textTaskToKillCounter;
          text = text.replaceFirst('%n', killedTanks.toString());
        }
        game.showScenarioMessage(TalkDialog(
          // nextOnTap: true,
          // nextOnAnyKey: true,
          says: [
            Say(
              text: [TextSpan(text: text)],
            ),
          ],
          key: UniqueKey(),
        ));
      }
    }
  }

  @override
  void scriptUpdate(double dt) {
    // TODO: implement scriptUpdate
  }

  void scriptFinish() {
    removeFromParent();
    game.world.scenarioLayer.children
        .whereType<TrackTankCreation>()
        .forEach(game.world.scenarioLayer.remove);
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
