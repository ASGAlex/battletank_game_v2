import 'dart:async';

import 'package:flame/experimental.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/audio/effect_loop/effect_loop.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_audio_effect.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_forward_collision.dart';
import 'package:tank_game/world/core/direction.dart';

class PlayerControlledBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  @override
  FutureOr<void> onLoad() {
    listenProvider(game.inputEventsHandler.messageProvider);
    priority = -1;
  }

  static final ignoredEvents = <PlayerAction>{};

  MovementForwardCollisionBehavior get movementForward {
    _cachedBehavior ??= parent.findBehavior<MovementForwardCollisionBehavior>();
    return _cachedBehavior!;
  }

  MovementForwardCollisionBehavior? _cachedBehavior;

  @override
  void onMount() {
    if (SettingsController().soundEnabled) {
      AudioEffectLoop? audioEffectLoop;
      if (parent is TankEntity) {
        audioEffectLoop = AudioEffectLoop(
          effectFile: 'sfx/move_player.m4a',
          effectDuration: const Duration(milliseconds: 990),
        );
      } else if (parent is HumanEntity) {
        audioEffectLoop = AudioEffectLoop(
          effectFile: 'sfx/human_step_grass.m4a',
          effectDuration: const Duration(milliseconds: 1000),
        );
      }
      if (audioEffectLoop != null) {
        parent.add(MovementAudioEffectBehavior(effect: audioEffectLoop));
      }
    }
    super.onMount();
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    if (isRemoved || isRemoving) {
      return;
    }
    var isMovementAction = false;
    for (final msg in message) {
      if (ignoredEvents.contains(msg)) {
        continue;
      }
      switch (msg) {
        case PlayerAction.moveUp:
          parent.lookDirection = DirectionExtended.up;
          isMovementAction = true;
          break;
        case PlayerAction.moveDown:
          parent.lookDirection = DirectionExtended.down;
          isMovementAction = true;
          break;
        case PlayerAction.moveLeft:
          parent.lookDirection = DirectionExtended.left;
          isMovementAction = true;
          break;
        case PlayerAction.moveRight:
          parent.lookDirection = DirectionExtended.right;
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
      } else {
        parent.coreState = ActorCoreState.idle;
      }
    }
  }

  @override
  void onRemove() {
    if (!isRemoved) {
      try {
        final audioEffect = parent.findBehavior<MovementAudioEffectBehavior>();
        audioEffect.removeFromParent();
      } catch (_) {}
      disposeListener();
      super.onRemove();
    }
  }
}
