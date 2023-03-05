import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/environment/brick.dart';
import 'package:tank_game/world/environment/heavy_brick.dart';
import 'package:tank_game/world/tank/enemy.dart';

import '../environment/spawn.dart';
import '../environment/tree.dart';
import '../environment/water.dart';
import '../sound.dart';
import '../world.dart';
import 'core/direction.dart';

enum BulletState { fly, boom, crater }

class Bullet extends SpriteAnimationGroupComponent<BulletState>
    with
        CollisionCallbacks,
        HideableComponent,
        HasGameRef<MyGame>,
        HasGridSupport {
  Bullet(
      {required this.direction,
      required this.firedFrom,
      this.damage = 1,
      super.position,
      super.angle})
      : super(anchor: Anchor.center) {
    current = BulletState.fly;
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.active;
  }

  final Direction direction;
  double damage = 1;
  int speed = 150;

  PositionComponent firedFrom;

  final distantSfxPlayer = DistantSfxPlayer(distanceOfSilenceSquared);
  double _distance = 0;
  final _maxDistance = 300;

  final _light = _Light();

  Duration? _boomDuration;
  Vector2 _boomSpriteSize = Vector2.zero();

  @override
  Future<void> onLoad() async {
    final boomTileCache = game.tilesetManager.getTile('boom', 'boom');
    final boom = boomTileCache?.spriteAnimation;
    if (boom == null) {
      throw "Can't load bullet's boom animation!";
    }
    _boomSpriteSize = boom.frames.first.sprite.srcSize;

    final craterTileCache = game.tilesetManager.getTile('boom', 'crater');
    final crater = craterTileCache?.sprite?.toAnimation();
    if (crater == null) {
      throw "Can't load boom's crate sprite!";
    }

    _boomDuration =
        Duration(milliseconds: (boom.totalDuration() * 1000).toInt());

    final bulletTileCache = game.tilesetManager.getTile('bullet', 'bullet');
    final bullet = bulletTileCache?.spriteAnimation;
    if (bullet == null) {
      throw "Can't load bullet's fly animation!";
    }

    size.setFrom(bullet.frames.first.sprite.srcSize);
    animations = {
      BulletState.fly: bullet,
      BulletState.boom: boom,
      BulletState.crater: crater
    };

    add(_light);

    Vector2 displacement;
    final diff = firedFrom.size.x / 2;
    switch (direction) {
      case Direction.left:
        displacement = position.translate(-diff, 0);
        break;
      case Direction.right:
        displacement = position.translate(diff, 0);
        break;
      case Direction.up:
        displacement = position.translate(0, -diff);
        break;
      case Direction.down:
        displacement = position.translate(0, diff);
        break;
    }
    position = displacement;
    angle = direction.angle;
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (!hidden) {
      super.render(canvas);
    }
  }

  @override
  void update(double dt) {
    if (current == BulletState.fly) {
      final innerSpeed = speed * dt;
      Vector2 displacement;
      switch (direction) {
        case Direction.left:
          displacement = position.translate(-innerSpeed, 0);
          break;
        case Direction.right:
          displacement = position.translate(innerSpeed, 0);
          break;
        case Direction.up:
          displacement = position.translate(0, -innerSpeed);
          break;
        case Direction.down:
          displacement = position.translate(0, innerSpeed);
          break;
      }
      position = displacement;
      _distance += innerSpeed;
      if (_distance > _maxDistance) {
        die(noHit: true);
      }
    }
    super.update(dt);
  }

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is Water ||
        other is Spawn ||
        other is Tree ||
        other == firedFrom ||
        (other is Bullet && firedFrom == other.firedFrom) ||
        current == BulletState.boom ||
        (firedFrom is Enemy && other is Enemy && !other.dead)) {
      return false;
    }
    return super.onComponentTypeCheck(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.inactive;

    Future<AudioPlayer>? sfx;
    if (other is Brick) {
      other.collideWithBullet(this);
      sfx = SoundLibrary.createSfxPlayer('player_bullet_wall.m4a');
    } else if (other is HeavyBrick) {
      sfx = SoundLibrary.createSfxPlayer('player_bullet_strong_wall.m4a');
    }

    sfx?.then((player) {
      distantSfxPlayer.actualDistance =
          (gameRef.player?.position.distanceToSquared(position) ??
              distanceOfSilenceSquared + 1);
      distantSfxPlayer.play(player);
    });

    die(skipRemove: true);

    if (other is DestroyableComponent) {
      other.takeDamage(damage, firedFrom);
    }

    super.onCollision(intersectionPoints, other);
  }

  die({bool skipRemove = false, bool noHit = false}) {
    if (!skipRemove) {
      boundingBox.collisionType =
          boundingBox.defaultCollisionType = CollisionType.passive;
    }

    removeFromParent();
    _light.renderShape = false;
    _light.removeFromParent();
    current = BulletState.boom;
    size.setFrom(_boomSpriteSize);

    if (_boomDuration != null) {
      Future.delayed(_boomDuration!).then((value) {
        if (noHit) {
          current = BulletState.crater;
          final layer = game.layersManager.addComponent(
              component: this,
              layerType: MapLayerType.trail,
              layerName: 'trail');
          if (layer is CellTrailLayer) {
            layer.fadeOutConfig = game.world.fadeOutConfig;
          }
        }
        removeFromParent();
      });
    }
  }
}

class _Light extends CircleComponent {
  _Light() : super(position: Vector2(1, 1), anchor: Anchor.center, radius: 16);

  @override
  Future onLoad() async {
    super.onLoad();
    paint = Paint();
    paint
      ..color = material.Colors.orangeAccent.withOpacity(0.3)
      ..blendMode = BlendMode.lighten
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        5,
      );
    return null;
  }
}
