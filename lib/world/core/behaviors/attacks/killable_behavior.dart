import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';

class KillableBehavior extends CollisionBehavior {
  @override
  void update(double dt) {}

  void applyAttack(AttackBehavior attackedBy) {
    parent.data.health -= attackedBy.parent.data.health;
    if (parent.data.health < 0) {
      killParent(attackedBy);
    }
  }

  void killParent(AttackBehavior attackedBy) {}
}
