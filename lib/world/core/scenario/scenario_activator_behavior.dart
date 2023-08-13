import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class ScenarioActivatorBehavior extends CollisionBehavior
    with ActivationCallbacks, HasGameReference<MyGame> {
  final activatedScenariosHistory = <ScenarioComponent>{};

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ScenarioComponent && !other.activated) {
      other.activatedBy(other, parent, game);
      activatedBy(other, parent, game);
      activatedScenariosHistory.add(other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is ScenarioComponent &&
        (!other.trackActivity || other.activated)) {
      other.deactivatedBy(other, parent, game);
      deactivatedBy(other, parent, game);
    }
    super.onCollisionEnd(other);
  }

  @override
  void onRemove() {
    activatedScenariosHistory.clear();
    super.onRemove();
  }
}
