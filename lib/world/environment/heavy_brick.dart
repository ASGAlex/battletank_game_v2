import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/world/world.dart';

class HeavyBrick extends SpriteComponent
    with CollisionCallbacks, DestroyableComponent {
  HeavyBrick(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.player.priority);

  TileProcessor tileProcessor;

  @override
  int health = 10000;

  @override
  Future<void> onLoad() async {
    sprite = await tileProcessor.getSprite();
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      add(collision);
    }
  }
}
