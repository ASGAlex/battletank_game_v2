import 'dart:async';

import 'package:flame/experimental.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/audio_effect_loop.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class PlayerControlledBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  @override
  FutureOr<void> onLoad() {
    listenProvider(game.inputEventsHandler.messageProvider);
    priority = -1;
    if (SettingsController().soundEnabled) {
      if (parent is TankEntity) {
        _audioEffectLoop = AudioEffectLoop(
          effectFile: 'music/move_player.m4a',
          effectDuration: const Duration(milliseconds: 990),
        );
      }
    }
  }

  AudioEffectLoop? _audioEffectLoop;

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
        case PlayerAction.triggerK:
          try {
            final killable =
                game.currentPlayer?.findBehavior<KillableBehavior>();
            killable?.killParent();
          } catch (_) {}
          break;
        default:
          // should not to handle
          break;
      }
    }
    if (parent.coreState != ActorCoreState.dying &&
        parent.coreState != ActorCoreState.removing &&
        parent.coreState != ActorCoreState.wreck) {
      if (isMovementAction) {
        parent.coreState = ActorCoreState.move;
        _audioEffectLoop?.play();
      } else {
        _audioEffectLoop?.stop();
        parent.coreState = ActorCoreState.idle;
      }
    }
  }

  @override
  void onRemove() {
    _audioEffectLoop?.dispose();
    dispose();
  }
}
