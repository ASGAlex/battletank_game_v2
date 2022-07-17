part of tank;

enum _BulletState { fly, boom }

class Bullet extends SpriteAnimationGroupComponent<_BulletState>
    with CollisionCallbacks, HideableComponent {
  Bullet(
      {required this.direction,
      required this.firedFrom,
      this.damage = 1,
      super.position,
      super.angle})
      : super(anchor: Anchor.center) {
    current = _BulletState.fly;
  }

  final Direction direction;
  int damage = 1;
  int speed = 150;

  PositionComponent firedFrom;

  final audioPlayer = DistantSfxPlayer(distanceOfSilence);
  double _distance = 0;
  final _maxDistance = 300;

  final _light = _Light();

  @override
  Future<void> onLoad() async {
    final boom = await SpriteSheetRegistry().boom.animation;
    size = SpriteSheetRegistry().bullet.spriteSize;
    animations = {
      _BulletState.fly: SpriteSheetRegistry().bullet.animation,
      _BulletState.boom: boom
    };
    boom.onComplete = () {
      hidden = false;
      removeFromParent();
    };
    add(_BulletHitbox(size: size.clone()));
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
    if (current == _BulletState.fly) {
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
        die();
      }
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (current == _BulletState.boom) return;
    if (other == firedFrom || other.parent == firedFrom || other is Spawn) {
      return;
    }
    if (firedFrom is Enemy && other is Enemy) return;
    if (other is WaterCollide) return;

    die();

    Sfx? sfx;
    if (other is Brick) {
      sfx = Sound().playerBulletWall;
    } else if (other is HeavyBrick) {
      sfx = Sound().playerBulletStrongWall;
    }

    if (sfx != null) {
      final game = findParent<MyGame>();
      audioPlayer.actualDistance =
          (game?.player?.position.distanceTo(position) ??
              distanceOfSilence + 1);
      audioPlayer.play(sfx);
    }

    if (other is DestroyableComponent) {
      other.takeDamage(damage);
    }

    super.onCollision(intersectionPoints, other);
  }

  die() {
    _light.renderShape = false;
    _light.removeFromParent();
    current = _BulletState.boom;
    size = SpriteSheetRegistry().boom.spriteSize;
  }
}

class _BulletHitbox extends RectangleHitbox {
  _BulletHitbox({super.size, super.position});

  @override
  void onCollision(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    if (other is HitboxNoInteraction) {
      return;
    }
    super.onCollision(intersectionPoints, other);
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
