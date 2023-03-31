import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement_behavior.dart';

abstract class MovementTrailBehavior extends Behavior<ActorMixin> {
  @override
  void update(double dt) {
    try {
      final movementBehavior = parent.findBehavior<MovementBehavior>();
      if (!movementBehavior.lastDisplacement.isZero()) {
        updateTrail(movementBehavior.lastInnerSpeed);
      }
    } catch (e) {}
  }

  void updateTrail(double innerSpeed);
}
