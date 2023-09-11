import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/camera_zoom_effect.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/hud/radar.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_player_out.dart';
import 'package:tank_game/world/core/behaviors/movement/available_direction_checker.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/scenario/components/area_collision_high_precision.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/environment/spawn/spawn_core_entity.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';

mixin PlayerControlledTransitionInfo on ActorMixin {
  var playerControlTransitionInProgress = false;

  ActorMixin? nextPlayerController;
}

class InteractionSetPlayer extends InteractableBehavior {
  InteractionSetPlayer({this.removeAfterSet = true})
      : super(trigger: InteractableTrigger.userAction);

  final bool removeAfterSet;
  ActorMixin? prevPlayerEntity;
  var _actionInProgress = false;

  bool get actionInProgress => _actionInProgress;
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
      if (currentPlayerEntity is PlayerControlledTransitionInfo) {
        currentPlayerEntity.playerControlTransitionInProgress = true;
        currentPlayerEntity.nextPlayerController = parent;
      }
      try {
        final playerControlled =
            currentPlayerEntity.findBehavior<PlayerControlledBehavior>();
        playerControlled.removeFromParent();
        paused = true;
        currentPlayerEntity.coreState = ActorCoreState.idle;
        if (removeAfterSet) {
          final children = currentPlayerEntity.children.query<ShapeHitbox>();
          for (final child in children) {
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

        try {
          final radar = currentPlayerEntity.findBehavior<RadarBehavior>();
          if (radar.keep) {
            radar.parent = parent;
          }
        } catch (_) {}

        parent.coreState = ActorCoreState.idle;
        parent.add(PlayerControlledBehavior());
        try {
          final fireBulletBehavior = parent.findBehavior<FireBulletBehavior>();
          fireBulletBehavior.emitEvent = true;
        } catch (_) {}
        parent.data.factions.clear();
        parent.data.factions.addAll(currentPlayerEntity.data.factions);
        parent.recreateBoundingHitbox(null);
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
          if (parent is ScenarioEventEmitter) {
            (parent as ScenarioEventEmitter).scenarioEvent(
                EventSetPlayer(emitter: parent, name: 'PlayerSet'));
          }
        });
      } catch (error) {
        print(error);
      }
    }
    super.doTriggerAction();
    _actionInProgress = false;
    if (currentPlayerEntity is PlayerControlledTransitionInfo &&
        !removeAfterSet) {
      currentPlayerEntity.playerControlTransitionInProgress = false;
    }
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
