import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';
import 'package:tank_game/services/sound/library.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/environment/brick.dart';
import 'package:tank_game/world/environment/heavy_brick.dart';
import 'package:tank_game/world/environment/spawn.dart';
import 'package:tank_game/world/environment/water.dart';

import '../world.dart';
import 'core/direction.dart';
import 'core/hitbox_movement.dart';
import 'core/hitbox_movement_side.dart';
import 'enemy.dart';

enum BulletState { fly, boom, crater }

class Bullet extends SpriteAnimationGroupComponent<BulletState>
    with
        CollisionCallbacks,
        HideableComponent,
        CollisionQuadTreeController<MyGame> {
  Bullet(
      {required this.direction,
      required this.firedFrom,
      this.damage = 1,
      super.position,
      super.angle})
      : super(anchor: Anchor.center) {
    current = BulletState.fly;
  }

  final Direction direction;
  double damage = 1;
  int speed = 150;

  PositionComponent firedFrom;

  final audioPlayer = DistantSfxPlayer(distanceOfSilence);
  double _distance = 0;
  final _maxDistance = 300;

  final _light = _Light();

  Duration? _boomDuration;
  late _BulletHitbox _hitbox;

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

    _hitbox = _BulletHitbox(size: size.clone());
    add(_hitbox);
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
      // updateQuadTreeCollision(_hitbox);
      _distance += innerSpeed;
      if (_distance > _maxDistance) {
        die(noHit: true);
      }
    }
    super.update(dt);
  }

  @override
  bool broadPhaseCheck(PositionComponent other) {
    final success = super.broadPhaseCheck(other);

    if (success) {
      if (other is WaterCollide) return false;
      if (current == BulletState.boom) return false;
      if (other == firedFrom || other.parent == firedFrom || other is Spawn) {
        return false;
      }

      if (firedFrom is Enemy && other is Enemy && !other.dead) return false;
    }
    return success;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    removeQuadTreeCollision(_hitbox);

    Sfx? sfx;
    if (other is Brick) {
      other.collideWithBullet(this);
      sfx = SoundLibrary().playerBulletWall;
    } else if (other is HeavyBrick) {
      sfx = SoundLibrary().playerBulletStrongWall;
    }

    die(skipRemove: true);

    if (sfx != null) {
      final game = findParent<MyGame>();
      audioPlayer.actualDistance =
          (game?.player?.position.distanceTo(position) ??
              distanceOfSilence + 1);
      audioPlayer.play(sfx);
    }

    if (other is DestroyableComponent) {
      other.takeDamage(damage, firedFrom);
    }

    super.onCollision(intersectionPoints, other);
  }

  die({bool skipRemove = false, bool noHit = false}) {
    if (!skipRemove) {
      removeQuadTreeCollision(_hitbox);
    }

    _light.renderShape = false;
    _light.removeFromParent();
    current = BulletState.boom;
    size = SpriteSheetRegistry().boom.spriteSize;

    if (_boomDuration != null) {
      Future.delayed(_boomDuration!).then((value) {
        if (noHit) {
          current = BulletState.crater;
          game.backBuffer?.add(this);
        }
        removeFromParent();
      });
    }
  }
}

class _BulletHitbox extends RectangleHitbox
    with CollisionQuadTreeController<MyGame> {
  _BulletHitbox({super.size, super.position});

  @override
  bool broadPhaseCheck(PositionComponent other) {
    final success = super.broadPhaseCheck(other);
    if (success && (other is MovementSideHitbox || other is MovementHitbox)) {
      return false;
    }
    return success;
  }
}

class _Light extends CircleComponent {
  _Light({super.children})
      : super(position: Vector2(1, 1), anchor: Anchor.center, radius: 16);

  @override
  onLoad() {
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