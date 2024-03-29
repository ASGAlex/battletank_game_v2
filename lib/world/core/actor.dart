import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';
import 'package:tank_game/world/core/direction.dart';
import 'package:tank_game/world/core/faction.dart';

enum ActorCoreState { init, idle, move, dying, wreck, removing }

typedef DistanceFunction = void Function(Component, double, double);

mixin ActorWithSeparateBody on ActorMixin {
  var bodyHitbox = BodyHitbox();

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    add(bodyHitbox);
  }
}

mixin ActorWithBoundingBody on ActorMixin {
  @override
  BoundingHitboxFactory get boundingHitboxFactory =>
      () => BodyHitbox(parentWithGridSupport: this);
}

@immutable
class ChildrenChangeMessage {
  final Component child;
  final ChildrenChangeType type;

  const ChildrenChangeMessage(this.child, this.type);
}

class ChildrenChangeListener extends MessageListener<ChildrenChangeMessage> {
  final Function(ChildrenChangeMessage message) callback;

  ChildrenChangeListener(super.provider, this.callback);

  @override
  void onStreamMessage(ChildrenChangeMessage message) => callback(message);
}

mixin ChildrenChangeListenerMixin on Component {
  ChildrenChangeListener? _listener;

  @override
  FutureOr<void> onLoad() {
    if (parent is ActorMixin) {
      _listener = ChildrenChangeListener(
        (parent as ActorMixin).childrenChangeNotifier,
        onParentChildrenChanged,
      );
    }
    return super.onLoad();
  }

  void onParentChildrenChanged(ChildrenChangeMessage message);

  @override
  void onRemove() {
    _listener?.dispose();
    _listener = null;
    super.onRemove();
  }
}

mixin ActorMixin on HasGridSupport implements EntityMixin {
  ActorData data = ActorData();

  final distanceFunctions = <DistanceFunction>{};

  final childrenChangeNotifier = MessageStreamProvider<ChildrenChangeMessage>();

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => ActorDefaultHitbox();

  @override
  void onChildrenChanged(Component child, ChildrenChangeType type) {
    childrenChangeNotifier.sendMessage(ChildrenChangeMessage(child, type));
    super.onChildrenChanged(child, type);
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    transform.addListener(_updateData);
    _updateData();
  }

  @override
  void onRemove() {
    transform.removeListener(_updateData);
    childrenChangeNotifier.dispose();
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

  set lookDirection(DirectionExtended direction) {
    data.lookDirection = direction;
    angle = direction.angle;
  }

  DirectionExtended get lookDirection => data.lookDirection;

  @override
  void onCalculateDistance(
      Component other, double distanceX, double distanceY) {
    for (final function in distanceFunctions) {
      function.call(other, distanceX, distanceY);
    }
  }

  void onCoreStateChanged() {}

  void resetCamera() {
    final currentPlayer = (spatialGrid?.game as MyGame).currentPlayer;
    if (currentPlayer == this) {
      final game = (spatialGrid?.game as MyGame);
      game.camera.stop();
      game.camera.moveTo(game.initialPlayerPosition, speed: 100);
      game.camera.viewfinder.zoom = 5;
      game.restorePlayer();
    }
  }
}

class LookDirectionNotifier extends ValueNotifier<DirectionExtended> {
  LookDirectionNotifier(super.value);
}

class ActorData {
  double health = 1;
  double speed = 0;
  double cameraSpeed = 40;
  final lookDirectionNotifier = LookDirectionNotifier(DirectionExtended.up);

  DirectionExtended get lookDirection => lookDirectionNotifier.value;

  set lookDirection(DirectionExtended value) {
    lookDirectionNotifier.value = value;
  }

  ActorCoreState coreState = ActorCoreState.init;
  Vector2 positionCenter = Vector2.zero();
  Vector2 size = Vector2.zero();
  final factions = <Faction>{};
  double zoom = 4;

  final properties = HashMap<String, dynamic>();
}

class ActorDefaultHitbox extends BoundingHitbox {
  ActorDefaultHitbox({
    super.position,
    super.size,
    super.collisionType,
    super.parentWithGridSupport,
  });

  @override
  FutureOr<void> onLoad() {
    fastCollisionForRects = true;
    if (parent is ActorMixin) {
      cacheAbsoluteScaledSize = true;
      (parent as ActorMixin).scale.addListener(absoluteScaledSizeCacheReset);
      (parent as ActorMixin)
          .data
          .lookDirectionNotifier
          .addListener(absoluteScaledSizeCacheReset);

      (parent as ActorMixin)
          .data
          .lookDirectionNotifier
          .addListener(absoluteAngleCacheReset);
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    if (parent is ActorMixin) {
      (parent as ActorMixin).scale.removeListener(absoluteScaledSizeCacheReset);

      (parent as ActorMixin)
          .data
          .lookDirectionNotifier
          .removeListener(absoluteScaledSizeCacheReset);

      (parent as ActorMixin)
          .data
          .lookDirectionNotifier
          .removeListener(absoluteAngleCacheReset);
    }
    super.onRemove();
  }
}

class BodyHitbox extends ActorDefaultHitbox {
  BodyHitbox({
    super.size,
    super.position,
    super.collisionType,
    super.parentWithGridSupport,
  });

  @override
  FutureOr<void> onLoad() {
    collisionType = defaultCollisionType = CollisionType.active;
    fastCollisionForRects = true;
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
