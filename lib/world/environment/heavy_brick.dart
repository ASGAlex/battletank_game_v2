import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/packages/back_buffer/lib/batch_components.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/world/world.dart';

class HeavyBrick extends SpriteComponent
    with CollisionCallbacks, DestroyableComponent, BatchRender {
  HeavyBrick(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.walls.priority);

  TileProcessor tileProcessor;

  late StaticCollision _hitbox;

  @override
  int health = 10000;

  @override
  Future<void> onLoad() async {
    sprite = await tileProcessor.getSprite();
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      _hitbox = StaticCollision(collision);
      add(_hitbox);
    }
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
