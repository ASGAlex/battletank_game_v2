import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/material.dart' as material;
import 'package:tank_game/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/world/tank/type/controller.dart';
import 'package:tank_game/world/world.dart';

import '../../environment/tree.dart';
import '../../sound.dart';
import '../bullet.dart';
import '../enemy.dart';
import '../player.dart';
import 'direction.dart';
import 'hitbox_body.dart';
import 'hitbox_movement.dart';

enum TankState { run, idle, die, wreck }

class Tank extends SpriteAnimationGroupComponent<TankState>
    with
        KeyboardHandler,
        CollisionCallbacks,
        DestroyableComponent,
        HasGameRef<MyGame>,
        HideableComponent,
        HasGridSupport {
  Tank({super.position})
      : super(size: Vector2(16, 16), angle: 0, anchor: Anchor.center) {
    typeController = TankTypeController(this);
  }

  late final TankTypeController typeController;
  Direction lookDirection = Direction.up;
  int speed = 50;

  bool skipUpdateOnAngleChange = true;

  int _treesCount = 0;
  bool _isHiddenFromEnemy = false;

  bool get isHiddenFromEnemy => _isHiddenFromEnemy;

  var fireDelay = const Duration(seconds: 1);
  bool canFire = true;
  double _trackDistance = 0;

  bool get trackTreeCollisions => true;
  bool renderTrackTrail = true;

  @override
  double health = 1;

  double damage = 1;

  final movementHitbox = MovementHitbox();
  final bodyHitbox =
      BodyHitbox(position: Vector2.zero(), size: Vector2.all(16));

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

  // @override
  // bool onComponentTypeCheck(PositionComponent other) {
  //   if (other is Spawn) {
  //     return false;
  //   }
  //   return super.onComponentTypeCheck(other);
  // }

  @override
  Future<void>? onLoad() async {
    await typeController.onLoad();

    _boomDuration = typeController.type.animationDie.duration;

    current = TankState.idle;
    add(movementHitbox);
    updateSize();
    bodyHitbox.size.setFrom(size);
    add(bodyHitbox);
    await super.onLoad();

    // if (trackTreeCollisions) {
    //   gameRef.lazyCollisionService
    //       .addHitbox(
    //           position: position,
    //           size: size,
    //           layer: 'tree',
    //           type: CollisionType.active)
    //       .then((value) {
    //     _lazyTreeHitboxId = value;
    //   });
    // }
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
      bullet.currentCell = currentCell;
      gameRef.world.addBullet(bullet);
      SoundLibrary.createSfxPlayer('player_fire_bullet.m4a').then((player) {
        if (this is Player) {
          player.resume();
        } else {
          distantAudioPlayer.actualDistance =
              (gameRef.player?.position.distanceToSquared(position) ??
                  distanceOfSilenceSquared + 1);
          distantAudioPlayer.play(player);
        }
      });
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
        gameRef.world.addSky(ParticleSystemComponent(
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
      if (current == TankState.run && movementHitbox.isMovementAllowed) {
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
          // if (trackTreeCollisions) {
          //   gameRef.lazyCollisionService.updateHitbox(
          //       id: _lazyTreeHitboxId,
          //       position: position.translate(-_halfSizeX, -_halfSizeY),
          //       layer: 'tree',
          //       size: size);
          // }
          _trackDistance += innerSpeed;
          if (_trackDistance > 2 && renderTrackTrail) {
            _trackDistance = 0;
            final leftTrackPos = transform.localToGlobal(Vector2(0, 0));
            final rightTrackPos = transform.localToGlobal(Vector2(12, 0));

            // gameRef.backBuffer?.add(
            //     _TrackTrailComponent(position: leftTrackPos, angle: angle));
            // gameRef.backBuffer?.add(
            //     _TrackTrailComponent(position: rightTrackPos, angle: angle));
          }
          // if (_dtSumTreesCheck >= 2 && trackTreeCollisions) {
          //   gameRef.lazyCollisionService
          //       .getCollisionsCount(_lazyTreeHitboxId, 'tree')
          //       .then((value) {
          //     final isHidden = value >= 4;
          //
          //     if (isHidden != _isHiddenFromEnemy) {
          //       _isHiddenFromEnemy = isHidden;
          //       onHiddenFromEnemyChanged(isHidden);
          //     }
          //   });
          // }
        }
      }
      if (current != TankState.idle) {
        super.update(dt);
      }
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Tree) {
      _treesCount++;
      if (_treesCount >= 4) {
        _isHiddenFromEnemy = true;
        onHiddenFromEnemyChanged(_isHiddenFromEnemy);
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Tree) {
      _treesCount--;

      if (_treesCount < 4) {
        _isHiddenFromEnemy = false;
        onHiddenFromEnemyChanged(_isHiddenFromEnemy);
      }
    }
    super.onCollisionEnd(other);
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

  render(Canvas canvas) {
    canvas.drawRect(
        Rect.fromPoints(movementHitbox.position.toOffset(),
            (movementHitbox.position + movementHitbox.size).toOffset()),
        Paint()..color = Color.fromRGBO(0, 0, 255, 1));

    canvas.drawRect(
        Rect.fromPoints(boundingBox.position.toOffset(),
            (boundingBox.position + boundingBox.size).toOffset()),
        Paint()
          ..color = Color.fromRGBO(255, 0, 221, 1.0)
          ..style = PaintingStyle.stroke);
    // boundingBox.renderDebugMode(canvas);
    super.render(canvas);
  }

  void onHiddenFromEnemyChanged(bool isHidden) {}

  @override
  onDeath(Component killedBy) {
    if (current != TankState.wreck) {
      // gameRef.lazyCollisionService.removeHitbox(_lazyTreeHitboxId, 'tree');
      current = TankState.die;

      super.onDeath(killedBy);

      Future<AudioPlayer>? sfx;
      if (this is Player) {
        sfx = SoundLibrary.createSfxPlayer('explosion_player.m4a');
      } else if (this is Enemy) {
        sfx = SoundLibrary.createSfxPlayer('explosion_enemy.m4a');
      }

      sfx?.then((player) {
        if (this is Player) {
          player.resume();
        } else {
          distantAudioPlayer.actualDistance =
              (gameRef.player?.position.distanceToSquared(position) ??
                  distanceOfSilenceSquared + 1);
          distantAudioPlayer.play(player);
        }
      });

      if (_boomDuration != null) {
        Future.delayed(_boomDuration!).then((value) {
          current = TankState.wreck;
          _nextSmokeParticle = _nextSmokeParticleMax;
          health = 0.1;
        });
      }
    } else {
      // gameRef.backBuffer?.add(this);
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
