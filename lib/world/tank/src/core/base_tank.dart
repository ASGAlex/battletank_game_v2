part of tank;

enum MovementState { run, idle, die }

class Tank extends SpriteAnimationGroupComponent<MovementState>
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
  final _movementHitbox = _MovementHitbox();
  final _boundingHitbox = RectangleHitbox();

  SpriteAnimation? animationRun;
  SpriteAnimation? animationIdle;
  SpriteAnimation? animationDie;

  final audioPlayer = DistantSfxPlayer(distanceOfSilence);

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

    _boomDuration = animationDie!.duration;

    animations = {
      MovementState.run: animationRun!,
      MovementState.idle: animationIdle!,
      MovementState.die: animationDie!
    };

    current = MovementState.idle;
    add(_boundingHitbox);
    add(_movementHitbox);
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
      final sfx = Sound().playerFireBullet;
      if (this is Player) {
        sfx.controller?.setVolume(1);
        sfx.play();
      } else {
        audioPlayer.actualDistance =
            (game.player?.position.distanceTo(position) ??
                distanceOfSilence + 1);
        audioPlayer.play(sfx);
      }
      return true;
    }

    return false;
  }

  void onWeaponReloaded() {}

  @override
  void update(double dt) {
    _dtSumTreesCheck += dt;

    if (current == MovementState.run && canMoveForward) {
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

          TrackTrailController.addTrack(
              _TrackTrailNew(position: leftTrackPos, angle: angle));
          TrackTrailController.addTrack(
              _TrackTrailNew(position: rightTrackPos, angle: angle));
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

      super.update(dt);
    }
  }

  void onHiddenFromEnemyChanged(bool isHidden) {}

  @override
  onDeath() {
    game.lazyCollisionService.removeHitbox(_lazyTreeHitboxId, 'tree');
    super.onDeath();
    current = MovementState.die;

    Sfx? sfx;
    if (this is Player) {
      sfx = Sound().explosionPlayer;
    } else if (this is Enemy) {
      sfx = Sound().explosionEnemy;
    }

    if (sfx != null) {
      audioPlayer.actualDistance =
          (game.player?.position.distanceTo(position) ?? distanceOfSilence + 1);
      audioPlayer.play(sfx);
    }

    if (_boomDuration != null) {
      Future.delayed(_boomDuration!).then((value) {
        removeFromParent();
        hidden = true;
      });
    }
  }
}
