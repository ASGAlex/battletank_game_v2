import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_behavior.dart';
import 'package:tank_game/world/core/behaviors/animation/animation_group_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attack_behavior.dart';
import 'package:tank_game/world/core/behaviors/attacks/attacker_data.dart';
import 'package:tank_game/world/core/behaviors/movement/movement_behavior.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/environment/spawn/spawn_entity.dart';

class BulletData extends ActorData {
  /// -1 means infinity
  double range = -1;
  double fliedDistance = 0;
  double splash = -1;
  double haloRadius = 0;
  double haloBlur = 5;
  Color haloColor = Colors.orangeAccent.withOpacity(0.3);
}

class BulletEntity extends SpriteAnimationGroupComponent<ActorCoreState>
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        HasTrailSupport,
        ActorMixin {
  BulletEntity({
    required double speed,
    required Direction lookDirection,
    required double health,
    required this.owner,
    required double range,
    required this.animationConfigs,
    double haloRadius = 0,
    Vector2? offset,
  }) {
    anchor = Anchor.center;
    data = BulletData();
    (data as BulletData).range = range;
    (data as BulletData).haloRadius = haloRadius;
    data.health = health;
    data.speed = speed;
    data.lookDirection = lookDirection;
    position.setFrom(owner.position);
    if (offset != null) {
      position.add(offset);
    }

    boundingBox.defaultCollisionType =
        boundingBox.collisionType = CollisionType.active;
    currentCell = owner.currentCell;
  }

  HasGridSupport owner;
  final movementBehavior = MovementBehavior();
  final Map<ActorCoreState, AnimationConfig> animationConfigs;
  CircleComponent? halo;

  @override
  FutureOr<void> onLoad() {
    add(AnimationGroupBehavior<ActorCoreState>(
        animationConfigs: animationConfigs));
    add(movementBehavior);
    add(AttackBehavior());

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

    super.onLoad();

    if (data.coreState == ActorCoreState.init) {
      coreState = ActorCoreState.move;
    }
    angle = data.lookDirection.angle;
  }

  @override
  void onCoreStateChanged() {
    current = data.coreState;
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
    if (other is SpawnEntity || other == owner) {
      return false;
    }

    if (other is ActorMixin) {
      final otherFactions = other.data.factions;
      final myFactions = data.factions;
      for (final faction in otherFactions) {
        if (myFactions.contains(faction)) return false;
      }
    }
    return super.onComponentTypeCheck(other);
  }

  @override
  void update(double dt) {
    if (data.coreState == ActorCoreState.move) {
      final lastDisplacement = movementBehavior.lastDisplacement..absolute();
      var distance = lastDisplacement.x;
      if (distance == 0) {
        distance = lastDisplacement.y;
      }
      if (distance != 0) {
        final bulletData = data as BulletData;
        bulletData.fliedDistance += distance;
        if (bulletData.fliedDistance >= bulletData.range) {
          coreState = ActorCoreState.wreck;
        }
      }
    }
    super.update(dt);
  }
}

class FireBulletBehavior extends Behavior<ActorMixin> {
  FireBulletBehavior({
    required this.bulletsRootComponent,
    required this.animationFactory,
    this.bulletOffset,
    this.haloRadius = 0,
  });

  final _offsetRotations = <Direction, Vector2>{};
  final Map<ActorCoreState, AnimationConfig> Function() animationFactory;

  @override
  FutureOr<void> onLoad() {
    assert(parent.data is AttackerData);
    if (bulletOffset != null) {
      for (final possibleDirection in Direction.values) {
        var rotatedOffset = bulletOffset!.clone();
        switch (possibleDirection) {
          case Direction.up:
            break;
          case Direction.left:
            rotatedOffset.rotate(270 * pi / 180);
            break;
          case Direction.down:
            rotatedOffset.rotate(180 * pi / 180);
            break;
          case Direction.right:
            rotatedOffset.rotate(90 * pi / 180);
            break;
        }
        _offsetRotations[possibleDirection] = rotatedOffset;
      }
    }
    return super.onLoad();
  }

  AttackerData get attackerData => (parent.data as AttackerData);

  Component bulletsRootComponent;
  Vector2? bulletOffset;
  double haloRadius = 0;
  bool _tryFire = false;

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
        offset: offset,
        haloRadius: haloRadius);
    bulletsRootComponent.add(bullet);
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
}
