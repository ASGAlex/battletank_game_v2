import 'dart:async';

import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/direction.dart';

class PlayerControlledBehavior extends Behavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  @override
  FutureOr<void> onLoad() {
    listenProvider(game.inputEventsHandler.messageProvider);
    priority = -1;
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    var isMovementAction = false;
    for (final msg in message) {
      switch (msg) {
        case PlayerAction.moveUp:
          parent.lookDirection = Direction.up;
          isMovementAction = true;
          break;
        case PlayerAction.moveDown:
          parent.lookDirection = Direction.down;
          isMovementAction = true;
          break;
        case PlayerAction.moveLeft:
          parent.lookDirection = Direction.left;
          isMovementAction = true;
          break;
        case PlayerAction.moveRight:
          parent.lookDirection = Direction.right;
          isMovementAction = true;
          break;
        case PlayerAction.fire:
          try {
            parent.findBehavior<FireBulletBehavior>().tryFire();
          } on StateError catch (e) {
            print(e);
          }
          break;
        case PlayerAction.trigger:
          // TODO: Handle this case.
          break;
      }
    }
    if (isMovementAction) {
      parent.coreState = ActorCoreState.move;
    } else {
      parent.coreState = ActorCoreState.idle;
    }
  }

  @override
  void onRemove() {
    dispose();
  }
}
