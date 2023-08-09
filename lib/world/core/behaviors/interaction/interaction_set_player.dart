import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/camera_zoom_effect.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_player_out.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/scenario/components/area_collision_high_precision.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';

class InteractionSetPlayer extends InteractableBehavior {
  InteractionSetPlayer({this.removeAfterSet = true})
      : super(trigger: InteractableTrigger.userAction);

  final bool removeAfterSet;
  ActorMixin? prevPlayerEntity;
  var _actionInProgress = false;
  var paused = false;
  Function(ActorMixin newPlayerComponent)? onComplete;

  @override
  void doTriggerAction() {
    if (_actionInProgress || paused) {
      return;
    }
    _actionInProgress = true;
    final currentPlayerEntity = game.currentPlayer;
    if (currentPlayerEntity != null) {
      try {
        final playerControlled =
            currentPlayerEntity.findBehavior<PlayerControlledBehavior>();
        playerControlled.removeFromParent();
        paused = true;
        currentPlayerEntity.coreState = ActorCoreState.idle;
        if (removeAfterSet) {
          final children = currentPlayerEntity.children.toList(growable: false);
          for (final child in children) {
            if (child is! ShapeHitbox) {
              continue;
            }
            child.collisionType = CollisionType.inactive;
          }
          final effect = OpacityEffect.to(
            0.01,
            EffectController(duration: 0.75),
          );
          currentPlayerEntity.add(effect);
          effect.onComplete = currentPlayerEntity.removeFromParent;
          try {
            final shadow = currentPlayerEntity.findBehavior<ShadowBehavior>();
            shadow.removeFromParent();
          } catch (_) {}
        } else {
          prevPlayerEntity = currentPlayerEntity;
        }

        parent.coreState = ActorCoreState.idle;
        parent.add(PlayerControlledBehavior());
        parent.data.factions.clear();
        parent.data.factions.addAll(currentPlayerEntity.data.factions);
        if (!parent.hasBehavior<TriggerSpawnBehavior>()) {
          parent.add(TriggerSpawnBehavior());
          parent.boundingBox.collisionType =
              parent.boundingBox.defaultCollisionType = CollisionType.active;
        }
        if (!parent.hasBehavior<DetectableBehavior>()) {
          parent.add(DetectableBehavior(detectionType: DetectionType.visual));
          parent.add(DetectableBehavior(detectionType: DetectionType.audial));
        }
        if (!parent.hasBehavior<HideInTreesBehavior>()) {
          parent.add(HideInTreesBehavior());
        }
        if (!parent.hasBehavior<InteractionPlayerOut>()) {
          parent.add(InteractionPlayerOut());
        }
        if (!parent.hasBehavior<AvailableDirectionChecker>()) {
          parent.add(AvailableDirectionChecker(outerWidth: parent.width));
        }
        // parent.data.health = 1000000;

        removeNpcBehaviors();

        game.currentPlayer = parent;
        game.cameraComponent.viewfinder
            .add(CameraZoomEffect(parent.data.zoom, LinearEffectController(2)));
        game.cameraComponent.follow(game.currentPlayer!, maxSpeed: 7);
        Future.delayed(const Duration(seconds: 2)).then((value) {
          onComplete?.call(parent);
          game.cameraComponent.follow(game.currentPlayer!, maxSpeed: 40);
        });
      } catch (error) {
        print(error);
      }
    }
    super.doTriggerAction();
    _actionInProgress = false;
  }

  void removeNpcBehaviors() {
    try {
      final colorFilter = parent.findBehavior<ColorFilterBehavior>();
      colorFilter.removeFromParent();
    } catch (_) {}

    try {
      final detectors = parent.findBehaviors<DetectorBehavior>();
      for (final detector in detectors) {
        detector.disableCallbackOnRemove = false;
        detector.removeFromParent();
      }
    } catch (_) {}

    try {
      final movement = parent.findBehavior<RandomMovementBehavior>();
      movement.removeFromParent();
    } catch (_) {}

    try {
      final movement = parent.findBehavior<TargetedMovementBehavior>();
      movement.removeFromParent();
    } catch (_) {}
    if (parent is CollisionPrecisionMixin) {
      (parent as CollisionPrecisionMixin).setCollisionHighPrecision(true);
    }
  }
}

class EventSetPlayer extends ScenarioEvent {
  const EventSetPlayer({required super.emitter, required super.name});
}
