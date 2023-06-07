import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/faction.dart';

enum ActorCoreState { init, idle, move, dying, wreck, removing }

typedef DistanceFunction = void Function(Component, double, double);

mixin ActorWithSeparateBody on ActorMixin {
  final bodyHitbox = BodyHitbox();

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    bodyHitbox.size.setFrom(size);
    add(bodyHitbox);
  }
}

mixin ActorWithBoundingBody on ActorMixin {
  @override
  BoundingHitboxFactory get boundingHitboxFactory =>
      (parent) => BodyHitbox(parentWithGridSupport: parent);
}

mixin ActorMixin on HasGridSupport implements EntityMixin {
  ActorData data = ActorData();

  final distanceFunctions = <DistanceFunction>{};

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    transform.addListener(_updateData);
    _updateData();
  }

  @override
  void onRemove() {
    transform.removeListener(_updateData);
    super.onRemove();
  }

  void _updateData() {
    data.positionCenter.setFrom(boundingBox.aabbCenter);
    data.size.setFrom(boundingBox.size);
  }

  set coreState(ActorCoreState state) {
    if (data.coreState != state) {
      data.coreState = state;
      onCoreStateChanged();
    }
  }

  ActorCoreState get coreState => data.coreState;

  set lookDirection(Direction direction) {
    data.lookDirection = direction;
    angle = direction.angle;
  }

  Direction get lookDirection => data.lookDirection;

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    for (final function in distanceFunctions) {
      function.call(other, distanceX, distanceY);
    }
  }

  void onCoreStateChanged() {}

  void stopCameraFollowing() {
    final currentPlayer = (spatialGrid?.game as MyGame).currentPlayer;
    if (currentPlayer == this) {
      final camera = (spatialGrid?.game as MyGame).cameraComponent;
      camera.stop();
      (spatialGrid?.game as MyGame).restorePlayer();
    }
  }
}

class ActorData {
  double health = 1;
  double speed = 0;
  double cameraSpeed = 40;
  Direction lookDirection = Direction.up;
  ActorCoreState coreState = ActorCoreState.init;
  Vector2 positionCenter = Vector2.zero();
  Vector2 size = Vector2.zero();
  final factions = <Faction>[];
  double zoom = 4;

  final properties = HashMap<String, dynamic>();
}

class BodyHitbox extends BoundingHitbox {
  BodyHitbox({
    super.size,
    super.position,
    super.collisionType,
    super.parentWithGridSupport,
  });

  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.active;
    // debugMode = true;
    return super.onLoad();
  }

  @override
  void renderDebugMode(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = const Color.fromRGBO(255, 0, 0, 0.8)
        ..style = PaintingStyle.fill,
    );
  }
}
