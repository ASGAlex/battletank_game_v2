import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:tank_game/packages/tiled_utils/lib/tiled_utils.dart';
import 'package:tank_game/world/world.dart';

class WaterCollide extends PositionComponent with CollisionCallbacks {
  WaterCollide(this.tileProcessor, {super.position, super.size})
      : super(priority: RenderPriority.water.priority);

  TileProcessor tileProcessor;

  @override
  Future<void> onLoad() async {
    final collision = tileProcessor.getCollisionRect();
    if (collision != null) {
      collision.collisionType = CollisionType.passive;
      add(collision);
    }
  }
}
