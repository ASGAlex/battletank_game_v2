import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/camera_zoom_effect.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';

class InteractionPlayerOut extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  InteractionPlayerOut({this.action, this.createHuman = true});

  Function? action;
  final bool createHuman;
  var _actionInProgress = false;
  var paused = false;

  @override
  FutureOr<void> onLoad() {
    listenProvider(game.inputEventsHandler.messageProvider);
    return super.onLoad();
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    if (message.contains(PlayerAction.triggerF)) {
      doTriggerAction();
    }
  }

  void doTriggerAction() {
    if (_actionInProgress || paused) {
      return;
    }
    _actionInProgress = true;

    try {
      ActorMixin? restoredEntity;
      final interactionSetPlayer = parent.findBehavior<InteractionSetPlayer>();
      interactionSetPlayer.paused = false;
      paused = true;
      if (createHuman) {
        restoredEntity = HumanEntity()..isInteractionEnabled = true;
        restoredEntity.position
            .setFrom(parent.position + Vector2(0, parent.size.y));
        restoredEntity.data.factions.addAll(parent.data.factions);
        parent.parent?.add(restoredEntity);
      } else {
        restoredEntity = interactionSetPlayer.prevPlayerEntity;
      }
      if (restoredEntity != null) {
        final playerControlled =
            parent.findBehavior<PlayerControlledBehavior>();
        playerControlled.removeFromParent();
        restoredEntity.add(PlayerControlledBehavior());

        game.currentPlayer = restoredEntity;

        game.cameraComponent.follow(restoredEntity, maxSpeed: 7);
        game.cameraComponent.viewfinder.add(CameraZoomEffect(
            restoredEntity.data.zoom, LinearEffectController(2)));
        Future.delayed(const Duration(seconds: 2)).then((value) {
          game.cameraComponent.follow(restoredEntity!,
              maxSpeed: restoredEntity.data.cameraSpeed);
        });
      }
      action?.call();
      removeFromParent();
    } catch (error) {
      print(error);
    }
    _actionInProgress = false;
  }
}
