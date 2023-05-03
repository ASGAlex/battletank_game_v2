import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/faction.dart';

class KillableBehavior extends CoreBehavior<ActorMixin> {
  KillableBehavior({this.factionCheck, this.customApplyAttack}) {
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
  bool Function(ActorMixin attackedBy, ActorMixin killable)? customApplyAttack;

  void applyAttack(AttackBehavior attackedBy) {
    final killAllowed = factionCheck?.call(attackedBy.parent, parent) ?? true;
    if (killAllowed) {
      final processed =
          customApplyAttack?.call(attackedBy.parent, parent) ?? false;
      if (processed) {
        return;
      }
      parent.data.health -= attackedBy.parent.data.health;
      attackedBy.parent.data.health = 0;
      if (parent.data.health <= 0) {
        killParent(attackedBy);
      } else {
        try {
          final colorFilter = parent.findBehavior<ColorFilterBehavior>();
          colorFilter.applyNext();
        } catch (_) {}
      }
    }
  }

  void killParent(AttackBehavior attackedBy) {
    try {
      final filter = parent.findBehavior<ColorFilterBehavior>();
      filter.removeFromParent();
    } catch (_) {}
    if (parent.data.coreState == ActorCoreState.wreck) {
      parent.coreState = ActorCoreState.removing;
    } else if (parent.data.coreState != ActorCoreState.dying) {
      parent.coreState = ActorCoreState.dying;
    }
  }
}
