import 'package:flame/effects.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/detection/detectable_behavior.dart';
import 'package:tank_game/world/core/behaviors/detection/detector_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/interaction/interaction_player_out.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/environment/spawn/trigger_spawn_behavior.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';

class InteractionSetPlayer extends InteractableBehavior {
  InteractionSetPlayer({this.removeAfterSet = true})
      : super(trigger: InteractableTrigger.userAction);

  final bool removeAfterSet;
  ActorMixin? prevPlayerEntity;

  @override
  void doTriggerAction() {
    final currentPlayerEntity = game.currentPlayer;
    if (currentPlayerEntity != null) {
      final playerControlled =
          currentPlayerEntity.findBehavior<PlayerControlledBehavior>();
      playerControlled.removeFromParent();
      currentPlayerEntity.coreState = ActorCoreState.idle;
      if (removeAfterSet) {
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
      parent.data.health = 1000000;

      removeNpcBehaviors();

      game.currentPlayer = parent;
      game.cameraComponent.follow(game.currentPlayer!, maxSpeed: 7);
      Future.delayed(const Duration(seconds: 2)).then((value) =>
          game.cameraComponent.follow(game.currentPlayer!, maxSpeed: 40));
    }
    super.doTriggerAction();
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
  }
}
