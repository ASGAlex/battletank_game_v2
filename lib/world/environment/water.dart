import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/world/world.dart';

class Water extends SpriteAnimationComponent
    with CollisionCallbacks, HasGridSupport {
  Water(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.water.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  TileDataProvider tileDataProvider;

  @override
  Future<void> onLoad() async {
    animation = await tileDataProvider.getSpriteAnimation();
    return super.onLoad();
  }
}
