import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_collision_high_precision.dart';
import 'package:tank_game/world/core/scenario/components/area_init_script.dart';
import 'package:tank_game/world/core/scenario/components/area_message.dart';
import 'package:tank_game/world/core/scenario/scenario_activator_behavior.dart';

typedef ScenarioCallbackFunction = void Function(
    ScenarioComponentCore scenario, ActorMixin actor, MyGame game);

typedef ScenarioTypeFactory = ScenarioComponent Function(TiledObject);

abstract class ScenarioComponentCore extends PositionComponent
    with HasGridSupport, HasGameReference<MyGame> {
  ScenarioComponentCore({
    this.tiledObject,
    Iterable<Faction> factions = const [],
  }) {
    this.factions.addAll(factions);
  }

  TiledObject? tiledObject;
  late final String name;
  final factions = <Faction>{};
  bool removeWhenLeave = false;

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => ScenarioHitbox();
}

class ScenarioComponent<T extends ScenarioComponentCore>
    extends ScenarioComponentCore with ActivationCallbacks<T> {
  static final _availableTypes = <String, ScenarioTypeFactory>{};

  static registerType(String name, ScenarioTypeFactory factory) {
    _availableTypes[name] = factory;
  }

  static restoreDefaults() {
    _availableTypes.clear();
    _availableTypes.addAll({
      'AreaMessage': (tiledObject) =>
          AreaMessageComponent(tiledObject: tiledObject),
      'AreaInitScript': (tiledObject) =>
          AreaInitScriptComponent(tiledObject: tiledObject),
      'AreaCollisionHighPrecision': (tiledObject) =>
          AreaCollisionHighPrecisionComponent(tiledObject: tiledObject),
    });
  }

  static ScenarioComponent fromTiled(TiledObject tiledObject) {
    ScenarioTypeFactory? typeFactory;
    try {
      final typeName = tiledObject.properties.getValue<String>('type') ?? '';
      typeFactory = _availableTypes[typeName];
    } catch (_) {}
    if (typeFactory == null) {
      return ScenarioComponent(tiledObject: tiledObject);
    } else {
      return typeFactory.call(tiledObject);
    }
  }

  ScenarioComponent({
    super.tiledObject,
    Iterable<Faction> factions = const [],
  });

  @override
  bool onComponentTypeCheck(PositionComponent other) {
    if (!(other as ActorMixin).hasBehavior<ScenarioActivatorBehavior>()) {
      return false;
    }
    if (factions.isNotEmpty) {
      final otherFactions = other.data.factions;
      if (otherFactions.isNotEmpty) {
        for (final faction in otherFactions) {
          if (factions.contains(faction)) {
            return true;
          }
        }
      }
    }
    return true;
  }

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      final activationName = properties.getValue<String>('activationCallback');
      if (activationName != null) {
        activationCallback = game.scenario.customFunctions[activationName];
      }

      final deactivationName =
          properties.getValue<String>('deactivationCallback');
      if (deactivationName != null) {
        deactivationCallback = game.scenario.customFunctions[deactivationName];
      }

      String factionsString = properties.getValue<String>('factions') ?? '';
      if (factionsString.isNotEmpty) {
        final list = factionsString.split(',');
        for (final factionName in list) {
          factions.add(Faction(name: factionName.trim()));
        }
      }

      try {
        removeWhenLeave = properties.getValue<bool>('removeWhenLeave') ?? false;
      } catch (_) {}

      try {
        name = tiledObject!.name;
      } catch (_) {}

      if (position.isZero()) {
        position = Vector2(tiledObject!.x, tiledObject!.y);
      }
      if (size.isZero()) {
        size = Vector2(tiledObject!.width, tiledObject!.height);
      }
    }
    super.onLoad();
  }

  @override
  void deactivatedBy(T scenario, ActorMixin other, MyGame game) {
    if (scenario.removeWhenLeave) {
      removeFromParent();
    }
    super.deactivatedBy(scenario, other, game);
  }
}

class ScenarioHitbox extends BoundingHitbox {
  ScenarioHitbox() {
    collisionType = defaultCollisionType = CollisionType.passive;
    isSolid = true;
  }
}

mixin ActivationCallbacks<T extends ScenarioComponentCore> {
  bool _activated = false;

  bool get activated => _activated;

  ScenarioCallbackFunction? activationCallback;
  ScenarioCallbackFunction? deactivationCallback;

  @mustCallSuper
  void activatedBy(T scenario, ActorMixin other, MyGame game) {
    _activated = true;
    activationCallback?.call(scenario, other, game);
  }

  @mustCallSuper
  void deactivatedBy(T scenario, ActorMixin other, MyGame game) {
    _activated = false;
    deactivationCallback?.call(scenario, other, game);
  }
}
