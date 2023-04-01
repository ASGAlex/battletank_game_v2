import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';

abstract class MovementTrailBehavior extends Behavior<ActorMixin> {
  MovementTrailBehavior({required this.stepSize});

  double stepSize = 0;
  double stepDone = 0;

  @override
  void update(double dt) {
    try {
      final movementBehavior = parent.findBehavior<MovementBehavior>();
      if (!movementBehavior.lastDisplacement.isZero()) {
        stepDone += stepDoneCalculation(movementBehavior.lastDisplacement);
        if (stepDone >= stepSize) {
          stepDone = 0;
          updateTrail(movementBehavior.lastInnerSpeed);
        }
      }
    } catch (e) {}
  }

  double stepDoneCalculation(Vector2 lastDisplacement) {
    return lastDisplacement.x.abs() + lastDisplacement.y.abs();
  }

  void updateTrail(double innerSpeed);
}
