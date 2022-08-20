import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/tank/type/controller.dart';
import 'package:tank_game/world/world.dart';

import '../../sound.dart';
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
        HasGameRef<MyGame>,
        HideableComponent {
  Tank({super.position})
      : super(size: Vector2(16, 16), angle: 0, anchor: Anchor.center) {
    typeController = TankTypeController(this);
  }

  late final TankTypeController typeController;
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
  bool renderTrackTrail = true;

  @override
  double health = 1;

  double damage = 1;

  int _lazyTreeHitboxId = -1;
  final movementHitbox = MovementHitbox();
  final boundingHitbox = RectangleHitbox();

  final distantAudioPlayer = DistantSfxPlayer(distanceOfSilenceSquared);

  Duration? _boomDuration;

  var _halfSizeX = 0.0;
  var _halfSizeY = 0.0;

  updateSize() {
    _halfSizeX = size.x / 2;
    _halfSizeY = size.y / 2;
  }

  static const _nextSmokeParticleMax = 0.15;
  double _nextSmokeParticle = 0;

  @override
  Future<void> onLoad() async {
    await typeController.onLoad();

    _boomDuration = typeController.type.animationDie.duration;

    current = TankState.idle;
    add(boundingHitbox);
    add(movementHitbox);
    updateSize();
    await super.onLoad();

    if (trackTreeCollisions) {
      gameRef.lazyCollisionService
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
          damage: damage,
          firedFrom: this);
      gameRef.addBullet(bullet);
      final sfx = SoundLibrary.createSfxPlayer('player_fire_bullet.m4a');
      if (this is Player) {
        sfx.resume();
      } else {
        distantAudioPlayer.actualDistance =
            (gameRef.player?.position.distanceToSquared(position) ??
                distanceOfSilenceSquared + 1);
        distantAudioPlayer.play(sfx);
      }
      return true;
    }

    return false;
  }

  void onWeaponReloaded() {}

  @override
  void update(double dt) {
    if (current == TankState.wreck) {
      if (_nextSmokeParticle <= 0) {
        final r = Random();
        final newPos = position.translate(
            8 - r.nextInt(16).toDouble(), 8 - r.nextInt(16).toDouble());
        gameRef.addSky(ParticleSystemComponent(
            position: newPos,
            particle: AcceleratedParticle(
                acceleration:
                    Vector2(r.nextDouble() * 15, -r.nextDouble() * 15),
                speed: Vector2(r.nextDouble() * 30, -r.nextDouble() * 30),
                child: ComputedParticle(
                    lifespan: 5,
                    renderer: (Canvas c, Particle particle) {
                      final paint = Paint()
                        ..color = material.Colors.grey
                            .withOpacity(1 - particle.progress);
                      c.drawCircle(Offset.zero, particle.progress * 8, paint);
                    }))));
        _nextSmokeParticle = _nextSmokeParticleMax;
      } else {
        _nextSmokeParticle -= dt;
      }
      return;
    } else {
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
            gameRef.lazyCollisionService.updateHitbox(
                id: _lazyTreeHitboxId,
                position: position.translate(-_halfSizeX, -_halfSizeY),
                layer: 'tree',
                size: size);
          }
          _trackDistance += innerSpeed;
          if (_trackDistance > 2 && renderTrackTrail) {
            _trackDistance = 0;
            final leftTrackPos = transform.localToGlobal(Vector2(0, 0));
            final rightTrackPos = transform.localToGlobal(Vector2(12, 0));

            gameRef.backBuffer?.add(
                _TrackTrailComponent(position: leftTrackPos, angle: angle));
            gameRef.backBuffer?.add(
                _TrackTrailComponent(position: rightTrackPos, angle: angle));
          }
          if (_dtSumTreesCheck >= 2 && trackTreeCollisions) {
            gameRef.lazyCollisionService
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
      gameRef.lazyCollisionService.removeHitbox(_lazyTreeHitboxId, 'tree');
      current = TankState.die;

      super.onDeath(killedBy);

      AudioPlayer? sfx;
      if (this is Player) {
        sfx = SoundLibrary.createSfxPlayer('explosion_player.m4a');
      } else if (this is Enemy) {
        sfx = SoundLibrary.createSfxPlayer('explosion_enemy.m4a');
      }

      if (sfx != null) {
        if (this is Player) {
          sfx.resume();
        } else {
          distantAudioPlayer.actualDistance =
              (gameRef.player?.position.distanceToSquared(position) ??
                  distanceOfSilenceSquared + 1);
          distantAudioPlayer.play(sfx);
        }
      }

      if (_boomDuration != null) {
        Future.delayed(_boomDuration!).then((value) {
          current = TankState.wreck;
          _nextSmokeParticle = _nextSmokeParticleMax;
          health = 0.1;
        });
      }
    } else {
      gameRef.backBuffer?.add(this);
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
