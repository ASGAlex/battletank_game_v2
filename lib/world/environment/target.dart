import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/generated/l10n.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/game/flash_message.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/world/sound.dart';

import '../world.dart';

enum TargetState { alive, boom, dead }

class Target extends SpriteAnimationGroupComponent<TargetState>
    with DestroyableComponent, HasGameRef<MyGame>, HasGridSupport {
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
      this.protectFromEnemies = false}) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  bool primary;
  bool protectFromEnemies;

  @override
  double health = 1;

  Duration? _boomDuration;

  @override
  Future<void>? onLoad() async {
    final bigBoomTile = game.tilesetManager.getTile('boom_big', 'boom_big');
    final boomAnimation = bigBoomTile?.spriteAnimation;
    if (boomAnimation == null) {
      throw "Can't load boom animation!";
    }

    final targetAlive = game.tilesetManager.getTile('target', 'alive');
    final alive = targetAlive?.sprite;
    if (alive == null) {
      throw "Can't load alive target sprite!";
    }

    final targetDead = game.tilesetManager.getTile('target', 'dead');
    final dead = targetDead?.sprite;
    if (dead == null) {
      throw "Can't load dead target sprite!";
    }

    _boomDuration =
        Duration(milliseconds: (boomAnimation.totalDuration() * 1000).toInt());
    size.setFrom(alive.srcSize);

    animations = {
      TargetState.alive: alive.toAnimation(),
      TargetState.boom: boomAnimation,
      TargetState.dead: dead.toAnimation(),
    };
    current = TargetState.alive;
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
    final loc = gameRef.buildContext?.loc();
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
        gameRef.onObjectivesStateChange(loc.mo_primary_target_just_lost,
            FlashMessageType.danger, finishGame);
      } else {
        _primaryKillTargets--;
        var finishGame = false;
        if (_primaryKillTargets == 0) {
          finishGame = true;
        }
        gameRef.onObjectivesStateChange(loc.mo_primary_target_just_killed,
            FlashMessageType.good, finishGame);
      }
      SettingsController().currentMission.objectives =
          checkMissionObjectives(gameRef.context.loc());
    } else {
      if (protectFromEnemies) {
        _secondaryProtectTargets--;
        gameRef.onObjectivesStateChange(
            loc.mo_secondary_target_just_lost, FlashMessageType.danger);
      } else {
        _secondaryKillTargets--;
        gameRef.onObjectivesStateChange(
            loc.mo_secondary_target_just_killed, FlashMessageType.good);
      }
      SettingsController().currentMission.objectives =
          checkMissionObjectives(gameRef.context.loc());
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
    super.onDeath(killedBy);
    current = TargetState.boom;
    SoundLibrary.createSfxPlayer('explosion_player.m4a')
        .then((value) => value.resume());
    decreaseCounters();
    Future.delayed(_boomDuration!).then((value) {
      current = TargetState.dead;
      final layer = game.layersManager.addComponent(
          component: this, layerType: MapLayerType.trail, layerName: 'trail');
      if (layer is CellTrailLayer) {
        layer.fadeOutConfig = game.world.fadeOutConfig;
      }

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
