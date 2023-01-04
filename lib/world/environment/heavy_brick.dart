import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/back_buffer/lib/batch/batch_components.dart';
import 'package:tank_game/world/world.dart';

class HeavyBrick extends SpriteComponent
    with
        CollisionCallbacks,
        DestroyableComponent,
        BatchedComponent,
        HasGameReference<MyGame>,
        HasGridSupport {
  HeavyBrick(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.walls.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  TileDataProvider tileDataProvider;

  late StaticCollision _hitbox;

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
    _die();
    return super.onDeath(killedBy);
  }

  _die() {
    if (isRemoving) return;
    scheduleTreeUpdate();
    removeFromParent();
  }

  @override
  Future<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
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
