import 'package:flame/extensions.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/targeted_movement_behavior.dart';

mixin MovementFactoryMixin on ActorMixin {
  RandomMovementBehavior createRandomMovement();

  TargetedMovementBehavior createTargetedMovement(
      {required Vector2 targetPosition, required Vector2 targetSize});
}
