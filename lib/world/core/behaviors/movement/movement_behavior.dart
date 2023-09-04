import 'package:flame/components.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/direction.dart';

class MovementBehavior extends CoreBehavior<ActorMixin> {
  final lastDisplacement = Vector2.zero();
  double lastInnerSpeed = 0;
  bool pauseMovement = false;

  @override
  void update(double dt) {
    if (pauseMovement) {
      return;
    }

    lastDisplacement.setZero();
    lastInnerSpeed = 0;
    if (parent.data.coreState != ActorCoreState.move) {
      return;
    }
    lastInnerSpeed = parent.data.speed * dt;
    switch (parent.data.lookDirection) {
      case DirectionExtended.left:
        lastDisplacement.setValues(-lastInnerSpeed, 0);
        break;
      case DirectionExtended.right:
        lastDisplacement.setValues(lastInnerSpeed, 0);
        break;
      case DirectionExtended.up:
        lastDisplacement.setValues(0, -lastInnerSpeed);
        break;
      case DirectionExtended.down:
        lastDisplacement.setValues(0, lastInnerSpeed);
        break;
    }

    if (!lastDisplacement.isZero()) {
      parent.position.setFrom(parent.position + lastDisplacement);
    }
  }
}
