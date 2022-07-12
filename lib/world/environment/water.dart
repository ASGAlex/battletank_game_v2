import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/world/world.dart';

import '../../services/tiled_utils/tiled_utils.dart';

class WaterCollide extends SpriteComponent
    with CollisionCallbacks, DestroyableComponent {
  WaterCollide(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.water.priority);

  TileProcessor tileProcessor;

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
