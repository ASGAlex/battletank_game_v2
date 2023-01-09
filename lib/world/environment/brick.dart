import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/tank/bullet.dart';
import 'package:tank_game/world/tank/core/direction.dart';
import 'package:tank_game/world/world.dart';

class Brick extends SpriteComponent
    with CollisionCallbacks, HasGameReference<MyGame>, HasGridSupport {
  Brick(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.walls.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  TileDataProvider tileDataProvider;

  int _hitsByBullet = 0;
  static const halfBrick = 4.0;
  static final brickSize = Vector2.all(halfBrick * 2);

  @override
  Future<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
  }

  void collideWithBullet(Bullet bullet) {
    if (bullet.current == BulletState.boom) return;
    if (_hitsByBullet >= 1) {
      removeFromParent();
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
}
