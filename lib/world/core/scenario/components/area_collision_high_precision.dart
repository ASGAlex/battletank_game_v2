import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/movement/random_movement_behavior.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class AreaCollisionHighPrecisionComponent
    extends ScenarioComponent<AreaCollisionHighPrecisionComponent> {
  final tags = <String>[];

  AreaCollisionHighPrecisionComponent({
    super.tiledObject,
    List<String> tags = const [],
  }) {
    this.tags.addAll(tags);
  }

  @override
  bool get activated => false;

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      try {
        final tags = properties.getValue<String>('tags') ?? '';
        this.tags.addAll(tags.split(',').map((e) => e.trim()));
      } catch (_) {}
    }
    super.onLoad();
  }

  @override
  void activatedBy(AreaCollisionHighPrecisionComponent scenario,
      ActorMixin other, MyGame game) {
    super.activatedBy(scenario, other, game);
    if (other.hasBehavior<PlayerControlledBehavior>()) {
      return;
    }

    if (other is CollisionPrecisionMixin) {
      (other as CollisionPrecisionMixin).setCollisionHighPrecision(true, tags);
      (other as CollisionPrecisionMixin).forceHighPrecision = true;
    } else {
      final hitboxes = other.children.whereType<BoundingHitbox>();
      for (final hitbox in hitboxes) {
        hitbox.groupCollisionsTags
            .removeWhere((element) => tags.contains(element));
        hitbox.collisionCheckFrequency = -1;
      }
    }
  }

  @override
  void deactivatedBy(AreaCollisionHighPrecisionComponent scenario,
      ActorMixin other, MyGame game) {
    super.deactivatedBy(scenario, other, game);

    if (other is CollisionPrecisionMixin) {
      (other as CollisionPrecisionMixin).forceHighPrecision = false;
      (other as CollisionPrecisionMixin).setCollisionHighPrecision(false, tags);
    } else {
      final hitboxes = other.children.whereType<BoundingHitbox>();
      for (final hitbox in hitboxes) {
        hitbox.groupCollisionsTags.addAll(tags);
      }
    }
  }
}

mixin CollisionPrecisionMixin on HasGridSupport {
  bool forceHighPrecision = false;

  List<BoundingHitbox> setCollisionHighPrecision(
    bool highPrecision, [
    List<String> tags = const [],
  ]) {
    if (forceHighPrecision) {
      return [];
    }
    final hitboxes = children.whereType<BoundingHitbox>();
    if (highPrecision || forceHighPrecision) {
      for (final hitbox in hitboxes) {
        if (tags.isEmpty) {
          hitbox.groupCollisionsTags.clear();
        } else {
          hitbox.groupCollisionsTags
              .removeWhere((element) => tags.contains(element));
        }
        hitbox.collisionCheckFrequency = -1;
      }
      if (this is EntityMixin) {
        try {
          (this as EntityMixin)
              .findBehavior<RandomMovementBehavior>()
              .trackCorners = true;
        } catch (_) {}
      }
    } else {
      if (this is EntityMixin) {
        try {
          (this as EntityMixin)
              .findBehavior<RandomMovementBehavior>()
              .trackCorners = false;
        } catch (_) {}
      }
    }
    return hitboxes.toList(growable: false);
  }
}
