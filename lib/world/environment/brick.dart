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
    final vector = center - bullet.center;
    if (vector.x.abs() > vector.y.abs()) {
      //horizontal
      if (vector.x > 0) {
        //from left
        if (_hitsByBullet == 0) {
          size.x -= halfBrick;
          position.x += halfBrick;
        } else {
          _die();
        }
      } else {
        //from right
        if (_hitsByBullet == 0) {
          size.x -= halfBrick;
        } else {
          _die();
        }
      }
    } else {
      //vertical
      if (vector.y > 0) {
        //from top
        if (_hitsByBullet == 0) {
          size.y -= halfBrick;
          position.y += halfBrick;
        } else {
          _die();
        }
      } else {
        //from bottom
        if (_hitsByBullet == 0) {
          size.y -= halfBrick;
        } else {
          _die();
        }
      }
    }
    _hitsByBullet++;
  }

  _die() {
    if (isRemoving) return;
    removeFromParent();
  }
}
