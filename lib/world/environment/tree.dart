import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/world.dart';

class Tree extends SpriteComponent
    with HasGridSupport, HasGameReference<MyGame> {
  Tree(this.tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }

  static Image? _treeImage;

  TileDataProvider tileDataProvider;

  @override
  Future<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    _treeImage ??= await game.world.createShadowOfComponent(this, super.render);
    super.onLoad();
  }

  @override
  render(Canvas canvas) {
    final offset =
        Offset(-game.world.shadowOffset, game.world.shadowOffset) * 1.5;
    canvas.drawImage(_treeImage!, offset, paint);
    super.render(canvas);
  }
}
