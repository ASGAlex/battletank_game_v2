import 'package:flame/components.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/scenario/scenario_object.dart';

class ScenarioActivatorBehavior extends CollisionBehavior
    with ActivationCallbacks {
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ScenarioObject) {
      other.activationCallback?.call(other, parent);
      activationCallback?.call(other, parent);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ScenarioObject) {
      other.deactivationCallback?.call(other, parent);
      deactivationCallback?.call(other, parent);
    }
    super.onCollisionEnd(other);
  }
}
