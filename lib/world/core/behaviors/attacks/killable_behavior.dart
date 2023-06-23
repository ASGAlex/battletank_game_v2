import 'dart:async';

import 'package:tank_game/services/audio/sfx.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/color_filter_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
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

  @override
  FutureOr<void> onLoad() {
    if (SettingsController().soundEnabled) {
      if (parent is TankEntity) {
        _audioEnemy = Sfx(effectName: 'sfx/explosion_enemy.m4a');
        _audioPlayer = Sfx(effectName: 'sfx/explosion_player.m4a');
      } else if (parent is HumanEntity) {
        _audioEnemy = Sfx(effectName: 'sfx/human_death.m4a');
      }
    }
    return super.onLoad();
  }

  Sfx? _audioEnemy;
  Sfx? _audioPlayer;

  bool applyAttack(AttackBehavior attackedBy) {
    final killAllowed = factionCheck?.call(attackedBy.parent, parent) ?? true;
    if (killAllowed) {
      final processed =
          customApplyAttack?.call(attackedBy.parent, parent) ?? false;
      if (processed) {
        return false;
      }
      parent.data.health -= attackedBy.parent.data.health;
      attackedBy.parent.data.health = 0;
      if (parent.data.health <= 0) {
        killParent(attackedBy);

        if (parent.data.coreState != ActorCoreState.removing) {
          return true;
        }
        return false;
      } else {
        try {
          final colorFilter = parent.findBehavior<ColorFilterBehavior>();
          colorFilter.applyNext();
        } catch (_) {}
      }
    }
    return false;
  }

  void killParent([AttackBehavior? attackedBy]) {
    try {
      final filter = parent.findBehavior<ColorFilterBehavior>();
      filter.removeFromParent();
    } catch (_) {}

    try {
      final controlled = parent.findBehavior<PlayerControlledBehavior>();
      controlled.removeFromParent();
      _audioPlayer?.play();
    } catch (_) {
      if (parent.data.coreState != ActorCoreState.wreck) {
        _audioEnemy?.play();
      }
    }
    if (parent.data.coreState == ActorCoreState.wreck) {
      parent.coreState = ActorCoreState.removing;
    } else if (parent.data.coreState != ActorCoreState.dying) {
      parent.coreState = ActorCoreState.dying;
    }
  }

  @override
  void onRemove() {
    if (!isRemoved) {
      _audioPlayer?.dispose();
      if (_audioPlayer != _audioEnemy) {
        _audioEnemy?.dispose();
      }
      super.onRemove();
    }
  }
}
