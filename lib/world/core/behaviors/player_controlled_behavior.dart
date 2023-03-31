import 'dart:async';

import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/tank/core/direction.dart';

class PlayerControlledBehavior extends Behavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<PlayerAction> {
  @override
  FutureOr<void> onLoad() {
    listenProvider(game.inputEventsHandler.messageProvider);
  }

  @override
  void onStreamMessage(PlayerAction message) {
    switch (message) {
      case PlayerAction.moveUp:
        parent.lookDirection = Direction.up;
        break;
      case PlayerAction.moveDown:
        parent.lookDirection = Direction.down;
        break;
      case PlayerAction.moveLeft:
        parent.lookDirection = Direction.left;
        break;
      case PlayerAction.moveRight:
        parent.lookDirection = Direction.right;
        break;
      case PlayerAction.fire:
        try {
          parent.findBehavior<AttackBehavior>().attack();
        } on StateError catch (e) {}
        break;
    }
  }

  @override
  void onRemove() {
    dispose();
  }
}
