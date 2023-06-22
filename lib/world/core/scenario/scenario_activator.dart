import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/scenario/scenario_object.dart';

class ScenarioActivatorBehavior extends CollisionBehavior
    with ActivationCallbacks, HasGameReference<MyGame> {
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ScenarioObject) {
      other.activationCallback?.call(other, parent, game);
      activationCallback?.call(other, parent, game);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ScenarioObject) {
      other.deactivationCallback?.call(other, parent, game);
      deactivationCallback?.call(other, parent, game);
    }
    super.onCollisionEnd(other);
  }
}
