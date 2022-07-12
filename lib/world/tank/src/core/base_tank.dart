part of tank;

enum MovementState { run, idle, die }

class Tank extends SpriteAnimationGroupComponent<MovementState>
    with
        KeyboardHandler,
        CollisionCallbacks,
        DestroyableComponent,
        HideableComponent {
  Tank({super.position})
      : super(size: Vector2(16, 16), angle: 0, anchor: Anchor.center);

  Direction lookDirection = Direction.right;
  int speed = 50;
  bool canMoveForward = true;
  // bool collisionCheckedAfterAngleUpdate = true;

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

  SpriteAnimation? animationRun;
  SpriteAnimation? animationIdle;
  SpriteAnimation? animationDie;

  final audioPlayer = DistantSfxPlayer(distantOfSilence);

  @override
  Future<void> onLoad() async {
    if (animationRun == null || animationIdle == null) {
      throw 'Animations required!';
    }

    animationDie ??= await SpriteSheetRegistry().boomBig.animation;
    animationDie?.onComplete = () {
      removeFromParent();
      hidden = true;
    };

    animations = {
      MovementState.run: animationRun!,
      MovementState.idle: animationIdle!,
      MovementState.die: animationDie!
    };

    current = MovementState.idle;
    add(RectangleHitbox());
    add(_movementHitbox);

    if (trackTreeCollisions) {
      final game = findParent<MyGame>();
      game?.lazyCollisionService
          .addHitbox(
              position: position,
              size: size,
              layer: 'tree',
              type: CollisionType.active)
          .then((value) {
        _lazyTreeHitboxId = value;
      });
    }

    return super.onLoad();
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
      findParent<MyGame>()?.addBullet(bullet);
      final sfx = Sound().playerFireBullet;
      if (this is Player) {
        sfx.controller?.setVolume(1);
        sfx.play();
      } else {
        final game = findParent<MyGame>();
        audioPlayer.actualDistance =
            (game?.player?.position.distanceTo(position) ?? 101);
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
    final game = findParent<MyGame>();

    if (current == MovementState.run &&
            canMoveForward /*&&
        collisionCheckedAfterAngleUpdate*/
        ) {
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
      position = displacement;
      if (trackTreeCollisions) {
        game?.lazyCollisionService.updateHitbox(
            id: _lazyTreeHitboxId,
            position: position.translate(-size.x / 2, -size.y / 2),
            layer: 'tree',
            size: size);
      }

      _trackDistance += innerSpeed;
      if (_trackDistance > 2) {
        _trackDistance = 0;
        final leftTrackPos = transform.localToGlobal(Vector2(0, 0));
        final rightTrackPos = transform.localToGlobal(Vector2(0, 12));
        // final game = findParent<MyGame>();
        // game?.addTrack(_TrackTrail(position: leftTrackPos, angle: angle));
        // game?.addTrack(_TrackTrail(position: rightTrackPos, angle: angle));
      }
    }

    if (_dtSumTreesCheck >= 0.5 && trackTreeCollisions) {
      game?.lazyCollisionService
          .getCollisionsCount(_lazyTreeHitboxId, 'tree')
          .then((value) {
        final isHidden = value >= 4;

        if (isHidden != _isHiddenFromEnemy) {
          _isHiddenFromEnemy = isHidden;
          onHiddenFromEnemyChanged(isHidden);
        }
      });
    }

    super.update(dt);
  }

  void onHiddenFromEnemyChanged(bool isHidden) {}

  @override
  onDeath() {
    final game = findParent<MyGame>();
    game?.lazyCollisionService.removeHitbox(_lazyTreeHitboxId, 'tree');
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
          (game?.player?.position.distanceTo(position) ?? 101);
      audioPlayer.play(sfx);
    }
  }
}
