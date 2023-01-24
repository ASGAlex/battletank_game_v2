import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/environment/shadow.dart';
import 'package:tank_game/world/world.dart';

class Tree extends SpriteComponent
    with HasGridSupport, HasGameReference<MyGame>, HasShadow {
  Tree(TileDataProvider tileDataProvider, {super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    this.tileDataProvider = tileDataProvider;
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = await tileDataProvider.getSprite();
    super.onLoad();
  }
}
