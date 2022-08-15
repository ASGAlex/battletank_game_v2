import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/generated/l10n.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/services/sound/library.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/intl.dart';

import '../world.dart';

enum TargetState { alive, boom, dead }

class Target extends SpriteAnimationGroupComponent<TargetState>
    with DestroyableComponent, MyGameRef {
  static int _primaryProtectTargets = 0;
  static int _primaryProtectTargetsMax = 0;

  static int _primaryKillTargets = 0;
  static int _primaryKillTargetsMax = 0;

  static int _secondaryProtectTargets = 0;
  static int _secondaryProtectTargetsMax = 0;

  static int _secondaryKillTargets = 0;
  static int _secondaryKillTargetsMax = 0;

  Target(
      {required super.position,
      this.primary = true,
      this.protectFromEnemies = false});

  bool primary;
  bool protectFromEnemies;

  @override
  int health = 1;

  final _hitbox = RectangleHitbox();
  Duration? _boomDuration;

  @override
  Future<void>? onLoad() async {
    final alive = await SpriteSheetRegistry().target.life;
    final boom = await SpriteSheetRegistry().boomBig.animation;
    final dead = await SpriteSheetRegistry().target.dead;
    _boomDuration = boom.duration;
    size = alive.frames.first.sprite.src.size.toVector2();

    animations = {
      TargetState.alive: alive,
      TargetState.boom: boom,
      TargetState.dead: dead,
    };
    current = TargetState.alive;
    add(_hitbox);
    increaseCounters();
    return super.onLoad();
  }

  increaseCounters() {
    if (primary) {
      if (protectFromEnemies) {
        _primaryProtectTargets++;
        _primaryProtectTargetsMax++;
      } else {
        _primaryKillTargets++;
        _primaryKillTargetsMax++;
      }
    } else {
      if (protectFromEnemies) {
        _secondaryProtectTargets++;
        _secondaryProtectTargetsMax++;
      } else {
        _secondaryKillTargets++;
        _secondaryKillTargetsMax++;
      }
    }
  }

  decreaseCounters() {
    final loc = game.buildContext?.loc();
    if (loc == null) {
      throw "Unexpected null locale";
    }
    if (primary) {
      if (protectFromEnemies) {
        _primaryProtectTargets--;
        var finishGame = false;
        if (_primaryProtectTargets == 0) {
          finishGame = true;
        }
        game.onObjectivesStateChange(loc.mo_primary_target_just_lost,
            FlashMessageType.danger, finishGame);
      } else {
        _primaryKillTargets--;
        var finishGame = false;
        if (_primaryKillTargets == 0) {
          finishGame = true;
        }
        game.onObjectivesStateChange(loc.mo_primary_target_just_killed,
            FlashMessageType.good, finishGame);
      }
      SettingsController().currentMission.objectives =
          checkMissionObjectives(game.context.loc());
    } else {
      if (protectFromEnemies) {
        _secondaryProtectTargets--;
        game.onObjectivesStateChange(
            loc.mo_secondary_target_just_lost, FlashMessageType.danger);
      } else {
        _secondaryKillTargets--;
        game.onObjectivesStateChange(
            loc.mo_secondary_target_just_killed, FlashMessageType.good);
      }
      SettingsController().currentMission.objectives =
          checkMissionObjectives(game.context.loc());
    }
  }

  static List<String> checkMissionObjectives(S loc) {
    final List<String> mission = [];
    if (_primaryProtectTargetsMax != 0) {
      mission.add(
          "${loc.mo_protect_primary_target(_primaryProtectTargetsMax)}.\r\n ${loc.mo_target_lost(_primaryProtectTargetsMax - _primaryProtectTargets)}");
    }

    if (_primaryKillTargetsMax != 0) {
      mission.add(
          "${loc.mo_kill_primary_target(_primaryKillTargetsMax)}.\r\n ${loc.mo_target_killed(_primaryKillTargetsMax - _primaryKillTargets)}");
    }

    if (_secondaryProtectTargetsMax != 0) {
      mission.add(
          "${loc.mo_protect_secondary_target(_secondaryProtectTargetsMax)}.\r\n ${loc.mo_target_lost(_secondaryProtectTargetsMax - _secondaryProtectTargets)}");
    }

    if (_secondaryKillTargetsMax != 0) {
      mission.add(
          "${loc.mo_kill_secondary_target(_secondaryKillTargetsMax)}.\r\n ${loc.mo_target_killed(_secondaryKillTargetsMax - _secondaryKillTargets)}");
    }

    return mission;
  }

  @override
  onDeath(Component killedBy) {
    remove(_hitbox);
    super.onDeath(killedBy);
    current = TargetState.boom;
    final sfx = SoundLibrary().explosionPlayer;
    sfx.play();
    decreaseCounters();
    Future.delayed(_boomDuration!).then((value) {
      current = TargetState.dead;
      game.backBuffer?.add(this);
      removeFromParent();
    });
  }

  static clear() {
    _primaryProtectTargets = 0;
    _primaryProtectTargetsMax = 0;

    _primaryKillTargets = 0;
    _primaryKillTargetsMax = 0;

    _secondaryProtectTargets = 0;
    _secondaryProtectTargetsMax = 0;

    _secondaryKillTargets = 0;
    _secondaryKillTargetsMax = 0;
  }
}
