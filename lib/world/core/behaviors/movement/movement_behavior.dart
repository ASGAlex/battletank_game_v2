import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/direction.dart';

class MovementBehavior extends Behavior<ActorMixin> {
  final lastDisplacement = Vector2.zero();
  double lastInnerSpeed = 0;

  @override
  void update(double dt) {
    lastDisplacement.setZero();
    lastInnerSpeed = 0;
    if (parent.data.coreState != ActorCoreState.move) {
      return;
    }
    lastInnerSpeed = parent.data.speed * dt;
    switch (parent.data.lookDirection) {
      case Direction.left:
        lastDisplacement.setValues(-lastInnerSpeed, 0);
        break;
      case Direction.right:
        lastDisplacement.setValues(lastInnerSpeed, 0);
        break;
      case Direction.up:
        lastDisplacement.setValues(0, -lastInnerSpeed);
        break;
      case Direction.down:
        lastDisplacement.setValues(0, lastInnerSpeed);
        break;
    }

    if (!lastDisplacement.isZero()) {
      parent.position.setFrom(parent.position + lastDisplacement);
    }
  }
}
