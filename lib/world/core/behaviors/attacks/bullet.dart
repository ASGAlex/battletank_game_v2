import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/audio/sfx/sfx.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/actors/human/human.dart';
import 'package:tank_game/world/actors/tank/tank.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attacker_data.dart';
import 'package:tank_game/world/core/behaviors/attacks/killable_behavior.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';
import 'package:tank_game/world/environment/tree/tree.dart';

mixin CanBurnTreesMixin on PositionComponent {}

class BulletData extends ActorData {
  /// -1 means infinity
  double range = -1;
  double fliedDistance = 0;
  double splash = -1;
  double haloRadius = 0;
  double haloBlur = 5;
  Color haloColor = Colors.orangeAccent.withOpacity(0.3);
  double speedPenalty = 0;
  double speedPenaltyDuration = 0;
  bool burnTrees = true;
}

class BulletEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin,
        HasGameReference<MyGame>,
        AnimationGroupCoreStateListenerMixin {
  BulletEntity({
    required double speed,
    required DirectionExtended lookDirection,
    required double health,
    required this.owner,
    required double range,
    required this.animationConfigs,
    required this.audio,
    double haloRadius = 0,
    double speedPenalty = 0,
    double speedPenaltyDuration = 0,
    Vector2? offset,
    bool burnTrees = true,
  }) {
    anchor = Anchor.center;
    data = BulletData();
    (data as BulletData).range = range;
    (data as BulletData).haloRadius = haloRadius;
    (data as BulletData).speedPenalty = speedPenalty;
    (data as BulletData).speedPenaltyDuration = speedPenaltyDuration;
    (data as BulletData).burnTrees = burnTrees;
    data.health = health;
    data.speed = speed;
    data.lookDirection = lookDirection;
    position.setFrom(owner.position);
    data.factions.addAll(owner.data.factions);
    if (offset != null) {
      position.add(offset);
    }

    boundingBox.defaultCollisionType =
        boundingBox.collisionType = CollisionType.active;
    currentCell = owner.currentCell;
    noVisibleChildren = true;
  }

  ActorMixin owner;
  final movementBehavior = MovementBehavior();
  late final AttackBehavior attackBehavior;
  final Map<ActorCoreState, AnimationConfig> animationConfigs;
  CircleComponent? halo;
  final Map<String, Sfx> audio;

  double _dtSpeed = 0;

  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.center;
    if (data.coreState == ActorCoreState.init) {
      coreState = ActorCoreState.move;
    }
    angle = data.lookDirection.angle;
    add(AnimationGroupBehavior<ActorCoreState>(
        animationConfigs: animationConfigs));
    add(movementBehavior);
    attackBehavior = AttackBehavior(audio);
    add(attackBehavior);
    add(KillableBehavior(factionCheck: null));

    final bulletData = (data as BulletData);
    if (bulletData.haloRadius > 0) {
      halo = CircleComponent(
        radius: bulletData.haloRadius,
        position: Vector2.all(-bulletData.haloRadius),
      );
      halo!.paint.blendMode = BlendMode.lighten;
      halo!.paint.color = bulletData.haloColor;
      if (bulletData.haloBlur > 0) {
        halo!.paint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          bulletData.haloBlur,
        );
      }
      add(halo!);
    }

    boundingBox.parentSpeedGetter = () => _dtSpeed;

    super.onLoad();
  }

  @override
  void onCoreStateChanged() {
    super.onCoreStateChanged();
    if (data.coreState == ActorCoreState.wreck) {
      final layer = sgGame.layersManager.addComponent(
        component: this,
        layerType: MapLayerType.trail,
        layerName: 'trail',
        optimizeCollisions: false,
      );
      if (layer is CellTrailLayer) {
        layer.fadeOutConfig = (sgGame as MyGame).world.fadeOutConfig;
      }
    }
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other == owner) {
      return false;
    }
    if (other is ActorMixin) {
      final otherFactions = other.data.factions;
      final myFactions = data.factions;
      for (final faction in otherFactions) {
        if (myFactions.contains(faction)) return false;
      }
    }
    return true;
  }

  @override
  void update(double dt) {
    if (data.coreState == ActorCoreState.move) {
      final newDtSpeed = data.speed * dt;
      if ((_dtSpeed - newDtSpeed).abs() > 0.5) {
        boundingBox.onParentSpeedChange();
      }
      _dtSpeed = newDtSpeed;
      final lastDisplacement = movementBehavior.lastDisplacement..absolute();
      var distance = lastDisplacement.x;
      if (distance == 0) {
        distance = lastDisplacement.y;
      }
      if (distance != 0) {
        final bulletData = data as BulletData;
        bulletData.fliedDistance += distance;
        if (bulletData.fliedDistance >= bulletData.range) {
          if ((data as BulletData).burnTrees) {
            game.world.bulletLayer
                .add(TreeBurner(position: position, currentCell: currentCell!));
          }
          coreState = ActorCoreState.wreck;
        }
      }
    }
    super.update(dt);
  }
}

class TreeBurner extends PositionComponent
    with HasGridSupport, CanBurnTreesMixin, CollisionCallbacks {
  TreeBurner({super.position, required Cell currentCell}) {
    currentCell = currentCell;
    size = Vector2.all(8);
    anchor = Anchor.center;
  }

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => TreeBurnerHitbox();

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is TreeEntity && other.state == TreeState.normal) {
      other.state = TreeState.burning;
      removeFromParent();
      return;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  bool checkFinished = false;

  @override
  void update(double dt) {
    if (checkFinished) {
      removeFromParent();
      return;
    }
    checkFinished = true;
  }
}

class TreeBurnerHitbox extends BodyHitbox {
  @override
  bool pureTypeCheck(Type other) {
    if (other == TreeBoundingHitbox) {
      return true;
    }
    return false;
  }
}

class FireBulletBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame>, ScenarioEventEmitter {
  FireBulletBehavior({
    required this.bulletsRootComponent,
    required this.animationFactory,
    this.bulletOffset,
    this.haloRadius = 0,
    this.scale = 1,
    this.speedPenalty = 0,
    this.speedPenaltyDuration = 0,
  });

  final _offsetRotations = <DirectionExtended, Vector2>{};
  final Map<ActorCoreState, AnimationConfig> Function() animationFactory;

  @override
  FutureOr<void> onLoad() {
    assert(parent.data is AttackerData);
    if (bulletOffset != null) {
      for (final possibleDirection in DirectionExtended.values) {
        var rotatedOffset = bulletOffset!.clone();
        switch (possibleDirection) {
          case DirectionExtended.up:
            break;
          case DirectionExtended.left:
            rotatedOffset.rotate(270 * pi / 180);
            break;
          case DirectionExtended.down:
            rotatedOffset.rotate(180 * pi / 180);
            break;
          case DirectionExtended.right:
            rotatedOffset.rotate(90 * pi / 180);
            break;
        }
        _offsetRotations[possibleDirection] = rotatedOffset;
      }
    }
    if (SettingsController().soundEnabled) {
      if (parent is TankEntity) {
        _audioFire = Sfx(effectName: 'sfx/player_fire_bullet.m4a');
      } else if (parent is HumanEntity) {
        _audioFire = Sfx(effectName: 'sfx/human_shoot.m4a');
      }
      _audioHit['weak'] = Sfx(effectName: 'sfx/player_bullet_wall.m4a');
      _audioHit['strong'] =
          Sfx(effectName: 'sfx/player_bullet_strong_wall.m4a');
      _audioHit['tank'] = Sfx(effectName: 'sfx/bullet_strong_tank.m4a');
    }
    return super.onLoad();
  }

  final _audioHit = <String, Sfx>{};
  Sfx? _audioFire;

  AttackerData get attackerData => (parent.data as AttackerData);

  Component bulletsRootComponent;
  Vector2? bulletOffset;
  double haloRadius = 0;
  bool _tryFire = false;
  double scale = 1;
  double speedPenalty = 0;
  double speedPenaltyDuration = 0;
  bool emitEvent = false;
  bool burnTrees = true;

  void tryFire() {
    _tryFire = true;
  }

  void doFire() {
    final offset = _offsetRotations[attackerData.lookDirection];
    final bullet = BulletEntity(
      owner: parent,
      animationConfigs: animationFactory.call(),
      range: attackerData.ammoRange,
      speed: attackerData.ammoSpeed,
      lookDirection: attackerData.lookDirection,
      health: attackerData.ammoHealth,
      speedPenalty: speedPenalty,
      speedPenaltyDuration: speedPenaltyDuration,
      offset: offset,
      audio: _audioHit,
      haloRadius: haloRadius,
      burnTrees: burnTrees,
    );
    bullet.scale = Vector2.all(scale);
    bulletsRootComponent.add(bullet);
    _audioFire?.play();
    if (emitEvent) {
      scenarioEvent(FireBulletEvent(emitter: bullet));
    }
  }

  @override
  void update(double dt) {
    if (attackerData.secondsElapsedBetweenFire <
        attackerData.secondsBetweenFire) {
      attackerData.secondsElapsedBetweenFire += dt;
    }

    if (_tryFire) {
      if (attackerData.secondsElapsedBetweenFire >=
              attackerData.secondsBetweenFire &&
          (attackerData.ammo > 0 || attackerData.ammo == -1)) {
        doFire();
        attackerData.secondsElapsedBetweenFire = 0;
      }
      _tryFire = false;
    }
    super.update(dt);
  }

  @override
  void onRemove() {
    _audioFire?.dispose();
    for (final poll in _audioHit.values) {
      poll.dispose();
    }
    _audioHit.clear();
    super.onRemove();
  }
}

class FireBulletEvent extends ScenarioEvent {
  const FireBulletEvent({required super.emitter})
      : super(name: 'FireBulletEvent');
}
