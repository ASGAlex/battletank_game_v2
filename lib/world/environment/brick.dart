import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';

import '../../services/tiled_utils/tiled_utils.dart';

class Brick extends SpriteComponent with CollisionCallbacks {
  Brick(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.player.priority);

  TileProcessor tileProcessor;

  int _hitsByBullet = 0;
  static const halfBrick = 4.0;
  static final brickSize = Vector2.all(halfBrick * 2);

  @override
  Future<void> onLoad() async {
    sprite = await tileProcessor.getSprite();
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      add(collision);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bullet) {
      _collideWithBullet(other);
    }

    super.onCollision(intersectionPoints, other);
  }

  void _collideWithBullet(Bullet bullet) {
    if (_hitsByBullet >= 1) {
      _die();
    } else {
      switch (bullet.direction) {
        case Direction.right:
          size.x -= halfBrick;
          position.x += halfBrick;
          break;
        case Direction.up:
          size.y -= halfBrick;
          break;
        case Direction.left:
          size.x -= halfBrick;
          break;
        case Direction.down:
          size.y -= halfBrick;
          position.y += halfBrick;
          break;
      }
    }
    _hitsByBullet++;
  }

  _die() {
    if (isRemoving) return;
    removeFromParent();
  }
}
