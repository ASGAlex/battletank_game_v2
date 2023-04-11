import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';
import 'package:tank_game/world/core/faction.dart';

class KillableBehavior extends CollisionBehavior {
  KillableBehavior({this.factionCheck}) {
    factionCheck ??= (attackedBy, killable) {
      final factionPlayer = Faction(name: 'Player');
      final factionEnemy = Faction(name: 'Enemy');
      if ((attackedBy.data.factions.contains(factionPlayer) &&
              killable.data.factions.contains(factionPlayer)) ||
          (attackedBy.data.factions.contains(factionEnemy) &&
              killable.data.factions.contains(factionEnemy))) {
        return false;
      }
      return true;
    };
  }

  bool Function(ActorMixin attackedBy, ActorMixin killable)? factionCheck;

  @override
  void update(double dt) {}

  void applyAttack(AttackBehavior attackedBy) {
    final killAllowed = factionCheck?.call(attackedBy.parent, parent) ?? true;
    if (killAllowed) {
      parent.data.health -= attackedBy.parent.data.health;
      attackedBy.parent.data.health = 0;
      if (parent.data.health <= 0) {
        killParent(attackedBy);
      }
    }
  }

  void killParent(AttackBehavior attackedBy) {
    if (parent.data.coreState == ActorCoreState.wreck) {
      parent.coreState = ActorCoreState.removing;
    } else {
      parent.coreState = ActorCoreState.dying;
    }
  }
}