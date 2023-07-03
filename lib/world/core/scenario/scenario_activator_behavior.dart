import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class ScenarioActivatorBehavior extends CollisionBehavior
    with ActivationCallbacks, HasGameReference<MyGame> {
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ScenarioComponent && !other.activated) {
      other.activatedBy(other, parent, game);
      activatedBy(other, parent, game);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ScenarioComponent && other.activated) {
      other.deactivatedBy(other, parent, game);
      deactivatedBy(other, parent, game);
    }
    super.onCollisionEnd(other);
  }
}
