import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/services/sound/library.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';
import 'package:tank_game/world/world.dart';

import '../bullet.dart';
import '../enemy.dart';
import '../player.dart';
import 'direction.dart';
import 'hitbox_movement.dart';

enum TankState { run, idle, die, wreck }

class Tank extends SpriteAnimationGroupComponent<TankState>
    with
        KeyboardHandler,
        CollisionCallbacks,
        CollisionQuadTreeController<MyGame>,
        DestroyableComponent,
        MyGameRef,
        HideableComponent {
  Tank({super.position})
      : super(size: Vector2(16, 16), angle: 0, anchor: Anchor.center);

  Direction lookDirection = Direction.up;
  int speed = 50;
  bool canMoveForward = true;
  bool skipUpdateOnAngleChange = true;

  bool _isHiddenFromEnemy = false;

  bool get isHiddenFromEnemy => _isHiddenFromEnemy;

  var fireDelay = const Duration(seconds: 1);
  bool canFire = true;
  double _trackDistance = 0;
  double _dtSumTreesCheck = 0;

  bool get trackTreeCollisions => true;

  @override
  int health = 1;

  int _lazyTreeHitboxId = -1;
  final movementHitbox = MovementHitbox();
  final boundingHitbox = RectangleHitbox();

  SpriteAnimation? animationRun;
  SpriteAnimation? animationIdle;
  SpriteAnimation? animationDie;
  SpriteAnimation? animationWreck;

  final distantAudioPlayer = DistantSfxPlayer(distanceOfSilence);

  Duration? _boomDuration;

  var _halfSizeX = 0.0;
  var _halfSizeY = 0.0;

  updateSize() {
    _halfSizeX = size.x / 2;
    _halfSizeY = size.y / 2;
  }

  @override
  Future<void> onLoad() async {
    if (animationRun == null || animationIdle == null) {
      throw 'Animations required!';
    }

    animationDie ??= await SpriteSheetRegistry().boomBig.animation;
    animationWreck ??= await SpriteSheetRegistry().tankBasic.animationWreck;

    _boomDuration = animationDie!.duration;

    animations = {
      TankState.run: animationRun!,
      TankState.idle: animationIdle!,
      TankState.die: animationDie!,
      TankState.wreck: animationWreck!
    };

    current = TankState.idle;
    add(boundingHitbox);
    add(movementHitbox);
    updateSize();
    await super.onLoad();

    if (trackTreeCollisions) {
      game.lazyCollisionService
          .addHitbox(
              position: position,
              size: size,
              layer: 'tree',
              type: CollisionType.active)
          .then((value) {
        _lazyTreeHitboxId = value;
      });
    }
  }

  bool onFire() {
    if (canFire) {
      canFire = false;
      Future.delayed(fireDelay).then((value) {
        canFire = true;
        onWeaponReloaded();
      });

      final bullet = Bullet(
          direction: lookDirection,
          angle: angle,
          position: position,
          firedFrom: this);
      game.addBullet(bullet);
      final sfx = SoundLibrary().playerFireBullet;
      if (this is Player) {
        sfx.play(volume: 1);
      } else {
        distantAudioPlayer.actualDistance =
            (game.player?.position.distanceTo(position) ??
                distanceOfSilence + 1);
        distantAudioPlayer.play(sfx);
      }
      return true;
    }

    return false;
  }

  void onWeaponReloaded() {}

  @override
  void update(double dt) {
    _dtSumTreesCheck += dt;

    if (current == TankState.run && canMoveForward) {
      if (skipUpdateOnAngleChange) {
        skipUpdateOnAngleChange = false;
        return;
      }
      final innerSpeed = speed * dt;
      Vector2 displacement;
      switch (lookDirection) {
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
      if (!displacement.isZero()) {
        position = displacement;
        if (trackTreeCollisions) {
          game.lazyCollisionService.updateHitbox(
              id: _lazyTreeHitboxId,
              position: position.translate(-_halfSizeX, -_halfSizeY),
              layer: 'tree',
              size: size);
        }
        _trackDistance += innerSpeed;
        if (_trackDistance > 2) {
          _trackDistance = 0;
          final leftTrackPos = transform.localToGlobal(Vector2(0, 0));
          final rightTrackPos = transform.localToGlobal(Vector2(12, 0));

          game.backBuffer
              ?.add(_TrackTrailComponent(position: leftTrackPos, angle: angle));
          game.backBuffer?.add(
              _TrackTrailComponent(position: rightTrackPos, angle: angle));
        }
        if (_dtSumTreesCheck >= 2 && trackTreeCollisions) {
          game.lazyCollisionService
              .getCollisionsCount(_lazyTreeHitboxId, 'tree')
              .then((value) {
            final isHidden = value >= 4;

            if (isHidden != _isHiddenFromEnemy) {
              _isHiddenFromEnemy = isHidden;
              onHiddenFromEnemyChanged(isHidden);
            }
          });
        }
      }
    }
    if (current != TankState.idle) {
      super.update(dt);
    }
  }

  @override
  void renderTree(Canvas canvas) {
    final settings = SettingsController();

    Color color = material.Colors.black;
    final shadowPaint = Paint()
      ..colorFilter = ColorFilter.mode(color.withOpacity(0.4), BlendMode.srcIn);
    if (settings.graphicsQuality != GraphicsQuality.low) {
      canvas.saveLayer(Rect.largest, shadowPaint);
      canvas.translate(-1.5, 1.5);
      canvas.transform(transformMatrix.storage);
      super.render(canvas);
      canvas.restore();
    }
    super.renderTree(canvas);
  }

  void onHiddenFromEnemyChanged(bool isHidden) {}

  @override
  onDeath(Component killedBy) {
    if (current != TankState.wreck) {
      game.lazyCollisionService.removeHitbox(_lazyTreeHitboxId, 'tree');
      current = TankState.die;

      super.onDeath(killedBy);

      Sfx? sfx;
      if (this is Player) {
        sfx = SoundLibrary().explosionPlayer;
      } else if (this is Enemy) {
        sfx = SoundLibrary().explosionEnemy;
      }

      if (sfx != null) {
        distantAudioPlayer.actualDistance =
            (game.player?.position.distanceTo(position) ??
                distanceOfSilence + 1);
        distantAudioPlayer.play(sfx);
      }

      if (_boomDuration != null) {
        Future.delayed(_boomDuration!).then((value) {
          current = TankState.wreck;
          health = 1;
        });
      }
    } else {
      game.backBuffer?.add(this);
      removeFromParent();
    }
  }
}

class _TrackTrailComponent extends PositionComponent with HasPaint {
  _TrackTrailComponent({super.position, super.angle}) {
    paint.color = material.Colors.black.withOpacity(0.5);
  }

  @override
  render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(0, 13, 4, 1), paint);
  }
}
