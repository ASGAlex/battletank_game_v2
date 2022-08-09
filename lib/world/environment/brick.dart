import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/back_buffer/lib/batch_components.dart';
import 'package:tank_game/packages/collision_quad_tree/lib/collision_quad_tree.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/world/tank/tank.dart';
import 'package:tank_game/world/world.dart';

class Brick extends SpriteComponent
    with
        CollisionCallbacks,
        CollisionQuadTreeController<MyGame>,
        MyGameRef,
        BatchRender {
  Brick(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.player.priority);

  TileProcessor tileProcessor;

  int _hitsByBullet = 0;
  static const halfBrick = 4.0;
  static final brickSize = Vector2.all(halfBrick * 2);

  late StaticCollision _hitbox;

  @override
  Future<void> onLoad() async {
    sprite = await tileProcessor.getSprite();
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      _hitbox = StaticCollision(collision);
      add(_hitbox);
    }
    super.onLoad();
  }

  void collideWithBullet(Bullet bullet) {
    if (bullet.current == BulletState.boom) return;
    game.batchRenderer?.imageChanged = true;
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
      _hitbox.size = size;
      updateQuadTreeCollision(_hitbox);
    }
    _hitsByBullet++;
  }

  _die() {
    if (isRemoving) return;
    scheduleTreeUpdate();
    removeFromParent();
    game.batchRenderer?.batchedComponents.remove(this);
  }

  @override
  Rect get sourceRect {
    var source = sprite!.src;
    if (size.x < 8) {
      source = Rect.fromLTWH(source.left, source.top, size.x, source.height);
    }
    if (size.y < 8) {
      source = Rect.fromLTWH(source.left, source.top, source.width, size.y);
    }
    return source;
  }
}
