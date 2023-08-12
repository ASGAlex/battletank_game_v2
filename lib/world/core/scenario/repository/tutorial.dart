import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:tank_game/ui/game/scenario/message_widget.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_event.dart';
import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
import 'package:tank_game/world/core/scenario/components/has_text_message_mixin.dart';
import 'package:tank_game/world/core/scenario/scenario_description.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/core/scenario/scripts/script_core.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';

class TutorialScenario extends Scenario {
  TutorialScenario({
    super.name = 'Tutorial',
    super.description = 'Learn how to play game',
  });

  @override
  String? get worldFile => 'tutorial.world';

  @override
  void onLoad() {
    super.onLoad();
    AreaInitScriptComponent.registerType('TutorialHowToUseTank',
        (lifetimeMax, creator) {
      return TutorialHowToUseTank(creator);
    });
    game.world.scenarioLayer.add(TrackTankCreation());
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

enum TutorialState {
  chooseTank(0),
  moveToPolygon(1),
  fireToWall(2);

  final int stage;

  const TutorialState(this.stage);
}

class TutorialHowToUseTank extends ScriptCore {
  TutorialHowToUseTank(AreaInitScriptComponent initializer) {
    txtMoveToPolygon = initializer.getTextMessage('txtMoveToPolygon');
  }

  late final String txtMoveToPolygon;

  TutorialState _state = TutorialState.chooseTank;

  ActorMixin? _currentTank;
  Widget? _previousContent;

  TutorialState get state => _state;

  set state(TutorialState value) {
    if (state == value) {
      return;
    }
    onChangeState(_state, value);
    _state = value;
  }

  void onChangeState(TutorialState newState, TutorialState previousState) {}

  @override
  void onStreamMessage(ScenarioEvent message) {
    switch (state) {
      case TutorialState.chooseTank:
        if (message is EventSetPlayer) {
          game.showScenarioMessage(MessageWidget(
            // nextOnTap: true,
            // nextOnAnyKey: true,
            texts: [txtMoveToPolygon],
            key: UniqueKey(),
          ));
          _currentTank = message.emitter as ActorMixin;
          state = TutorialState.moveToPolygon;
          AreaEventComponent.registerEvent(
              'InvalidPolygonEvent',
              ({
                required Component emitter,
                required String name,
                dynamic data,
              }) =>
                  InvalidPolygonEvent(emitter: emitter, data: data));
          AreaEventComponent.registerEvent(
              'TakePositionEvent',
              ({
                required Component emitter,
                required String name,
                dynamic data,
              }) =>
                  TakePositionEvent(emitter: emitter, data: data));
        }
        break;

      case TutorialState.moveToPolygon:
        if (message.emitter == _currentTank) {
          if (message.name == 'InvalidPolygonEvent') {
            final data = message.data;
            if (data is AreaEventData) {
              if (data.activated) {
                final text = data.properties?.getLocalizedTextMessage('text');
                if (text != null) {
                  if (game.isActiveScenarioMessage()) {
                    _previousContent = game.currentScenarioMessageContent;
                  }
                  game.showScenarioMessage(MessageWidget(
                    // nextOnTap: true,
                    // nextOnAnyKey: true,
                    texts: [text],
                    key: UniqueKey(),
                  ));
                }
              } else {
                if (_previousContent != null) {
                  game.showScenarioMessage(_previousContent!);
                } else {
                  game.hideScenarioMessage();
                }
              }
            }
          } else if (message.name == 'TakePositionEvent') {
            AreaEventComponent.unregisterEvent('InvalidPolygonEvent');
            AreaEventComponent.unregisterEvent('TakePositionEvent');
            final data = message.data;
            if (data is AreaEventData) {
              if (data.activated) {
                final text = data.properties?.getLocalizedTextMessage('text');
                if (text != null) {
                  game.showScenarioMessage(MessageWidget(
                    // nextOnTap: true,
                    // nextOnAnyKey: true,
                    texts: [text],
                    key: UniqueKey(),
                  ));
                }
                state = TutorialState.fireToWall;
              }
            }
          }
        }

        break;

      case TutorialState.fireToWall:
        break;
    }
  }

  @override
  void scriptUpdate(double dt) {
    // TODO: implement scriptUpdate
  }
}

class InvalidPolygonEvent extends ScenarioEvent {
  const InvalidPolygonEvent({required super.emitter, required super.data})
      : super(name: 'InvalidPolygonEvent');
}

class TakePositionEvent extends ScenarioEvent {
  const TakePositionEvent({required super.emitter, required super.data})
      : super(name: 'TakePositionEvent');
}
