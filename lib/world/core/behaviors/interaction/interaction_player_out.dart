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
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/camera_zoom_effect.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_set_player.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class InteractionPlayerOut extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  InteractionPlayerOut({this.action, this.createHuman = true});

  Function? action;
  final bool createHuman;
  var _actionInProgress = false;
  var paused = false;

  final Map<Direction, MovementCheckerHitbox> _availableDirections = {};

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

  @override
  void update(double dt) {
    if (_actionInProgress) {
      try {
        final directionChecker =
            parent.findBehavior<AvailableDirectionChecker>();
        _availableDirections
            .addAll(directionChecker.getAvailableDirectionsWithHitbox());
        print(_availableDirections);
        if (_availableDirections.isEmpty) {
          _actionInProgress = false;
          paused = false;
          return;
        }
        Direction? preferredDirection;
        for (final entry in _availableDirections.entries) {
          if (entry.value.direction == Direction.down) {
            preferredDirection = entry.key;
            break;
          }
          if (entry.value.direction == Direction.left ||
              entry.value.direction == Direction.right) {
            preferredDirection = entry.key;
          }
        }
        preferredDirection ??= _availableDirections.keys.first;

        final human = _createHuman(preferredDirection);
        _restoreEntity(human);
        _actionInProgress = false;
        _availableDirections.clear();
        directionChecker.disableSideHitboxes();
      } catch (_) {}
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
        try {
          final directionChecker =
              parent.findBehavior<AvailableDirectionChecker>();
          directionChecker.enableSideHitboxes();
          return;
        } catch (_) {
          restoredEntity = _createHuman();
        }
      } else {
        restoredEntity = interactionSetPlayer.prevPlayerEntity;
      }
      if (restoredEntity != null) {
        _restoreEntity(restoredEntity);
      }
      action?.call();
    } catch (error) {
      print(error);
    }
    _actionInProgress = false;
  }

  ActorMixin _createHuman([Direction direction = Direction.down]) {
    final restoredEntity = HumanEntity()
      ..isInteractionEnabled = true
      ..add(DetectableBehavior(detectionType: DetectionType.visual));

    switch (direction) {
      case Direction.down:
        restoredEntity.position
            .setFrom(parent.position + Vector2(0, parent.size.y));
        break;
      case Direction.up:
        restoredEntity.position
            .setFrom(parent.position + Vector2(0, -parent.size.y));
        break;
      case Direction.left:
        restoredEntity.position
            .setFrom(parent.position + Vector2(-parent.size.x, 0));
        break;
      case Direction.right:
        restoredEntity.position
            .setFrom(parent.position + Vector2(parent.size.x, 0));
        break;
    }
    restoredEntity.data.factions.addAll(parent.data.factions);
    parent.parent?.add(restoredEntity);

    return restoredEntity;
  }

  void _restoreEntity(ActorMixin restoredEntity) {
    final playerControlled = parent.findBehavior<PlayerControlledBehavior>();
    playerControlled.removeFromParent();
    restoredEntity.add(PlayerControlledBehavior());

    game.currentPlayer = restoredEntity;

    game.cameraComponent.follow(restoredEntity, maxSpeed: 7);
    game.cameraComponent.viewfinder.add(
        CameraZoomEffect(restoredEntity.data.zoom, LinearEffectController(2)));
    Future.delayed(const Duration(seconds: 2)).then((value) {
      game.cameraComponent
          .follow(restoredEntity, maxSpeed: restoredEntity.data.cameraSpeed);
    });

    removeFromParent();
  }
}
