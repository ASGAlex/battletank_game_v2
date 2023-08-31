import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/attacks/bullet.dart';
import 'package:tank_game/world/core/behaviors/effects/burning_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/shadow_behavior.dart';
import 'package:tank_game/world/environment/tree/hide_in_trees_behavior.dart';
import 'package:tank_game/world/world.dart';

enum TreeState {
  normal,
  burning,
  ash,
}

class TreeEntity extends SpriteComponent
    with
        CollisionCallbacks,
        EntityMixin,
        HasGridSupport,
        ActorMixin,
        HasGameReference<MyGame>,
        LayerCacheKeyProvider,
        UpdateOnDemand {
  TreeEntity({required super.sprite, super.position, super.size})
      : super(priority: RenderPriority.tree.priority) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    noVisibleChildren = true;
  }

  @override
  String getComponentUniqueString() =>
      '${super.getComponentUniqueString()},${state.name}';

  var _state = TreeState.normal;
  BurningBehavior? _burningBehavior;

  set state(TreeState value) {
    if (value == _state) {
      return;
    }

    if (_state == TreeState.normal && value == TreeState.burning) {
      _burningBehavior = BurningBehavior(
        burningPosition: absolutePosition.translated(-2, -8),
        rootComponent: game.world.skyLayer,
        duration: const Duration(seconds: 10),
        onBurningFinished: () {
          state = TreeState.ash;
        },
      );
      add(_burningBehavior!);
    } else if (value == TreeState.ash) {
      sprite = game.tilesetManager.getTile('bricks', 'tree_ash')?.sprite;
      _burningBehavior?.removeFromParent();
      if (parent is CellLayer) {
        (parent as CellLayer).cacheKey.invalidate();
        (parent as CellLayer).isUpdateNeeded = true;
      }
    }
    _state = value;
  }

  TreeState get state => _state;

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => TreeBoundingHitbox();

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (other is CanBurnTreesMixin) {
      return true;
    }
    if (other is HideInTreesOptimizedCheckerMixin && other.canHideInTrees) {
      return true;
    }

    return false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is HideInTreesOptimizedCheckerMixin) {
      other.hideInTreesBehavior?.collisionsWithTrees++;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is HideInTreesOptimizedCheckerMixin &&
        other.hideInTreesBehavior != null) {
      if (other.hideInTreesBehavior!.collisionsWithTrees > 0) {
        other.hideInTreesBehavior?.collisionsWithTrees--;
      }
    }
    super.onCollisionEnd(other);
  }

  @override
  FutureOr<void> onLoad() {
    add(ShadowBehavior(shadowKey: 'tree'));
    super.onLoad();
    boundingBox.collisionType =
        boundingBox.defaultCollisionType = CollisionType.passive;
    boundingBox.isSolid = true;
  }
}

class TreeBoundingHitbox extends BoundingHitbox {
  @override
  FutureOr<void> onLoad() {
    groupAbsoluteCacheByType = true;
    collisionType = defaultCollisionType = CollisionType.passive;
    return super.onLoad();
  }
}
