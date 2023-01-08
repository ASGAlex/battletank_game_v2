import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/world.dart';

class HeavyBrick extends SpriteComponent
    with
        CollisionCallbacks,
        DestroyableComponent,
        HasGameReference<MyGame>,
        HasGridSupport {
  HeavyBrick(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.walls.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  TileDataProvider tileDataProvider;

  @override
  double health = 2;

  @override
  takeDamage(double damage, Component from) {
    if (damage >= health) {
      super.takeDamage(damage, from);
    }
  }

  @override
  onDeath(Component killedBy) {
    removeFromParent();
    return super.onDeath(killedBy);
  }

  @override
  Future<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
  }
}
