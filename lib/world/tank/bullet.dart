import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
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

  @override
  Future<void> onLoad() async {
    final boom = await SpriteSheetRegistry().boom.boom;
    _boomDuration = boom.duration;
    size = SpriteSheetRegistry().bullet.spriteSize;
    animations = {
      BulletState.fly: SpriteSheetRegistry().bullet.animation,
      BulletState.boom: boom,
      BulletState.crater: await SpriteSheetRegistry().boom.crate
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
    //
    // if (success) {
    //   if (other is Water) return false;
    //   if (current == BulletState.boom) return false;
    //   if (other == firedFrom || other.parent == firedFrom || other is Spawn) {
    //     return false;
    //   }
    //
    //   if (firedFrom is Enemy && other is Enemy && !other.dead) return false;
    // }
    // return success;
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

    _light.renderShape = false;
    _light.removeFromParent();
    current = BulletState.boom;
    size = SpriteSheetRegistry().boom.spriteSize;

    if (_boomDuration != null) {
      Future.delayed(_boomDuration!).then((value) {
        if (noHit) {
          current = BulletState.crater;
          // gameRef.backBuffer?.add(this);
        }
        removeFromParent();
      });
    }
  }
}

class _Light extends CircleComponent {
  _Light({super.children})
      : super(position: Vector2(1, 1), anchor: Anchor.center, radius: 16);

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
