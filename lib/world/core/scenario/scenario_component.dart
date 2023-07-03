import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/components/area_message.dart';
import 'package:tank_game/world/core/scenario/scenario_activator_behavior.dart';

typedef ScenarioCallbackFunction = void Function(
    ScenarioComponentCore scenario, ActorMixin actor, MyGame game);

typedef ScenarioTypeFactory = ScenarioComponent Function(TiledObject);

abstract class ScenarioComponentCore extends PositionComponent
    with HasGridSupport, HasGameReference<MyGame> {
  ScenarioComponentCore({
    required this.name,
    required super.position,
    required super.size,
    Iterable<Faction> factions = const [],
  }) {
    this.factions.addAll(factions);
  }

  @protected
  TiledObject? tiledObject;
  final String name;
  final factions = <Faction>{};

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => ScenarioHitbox();
}

class ScenarioComponent<T extends ScenarioComponentCore>
    extends ScenarioComponentCore with ActivationCallbacks<T> {
  static final _availableTypes = <String, ScenarioTypeFactory>{};

  static registerType(String name, ScenarioTypeFactory factory) {
    _availableTypes[name] = factory;
  }

  static resetRegisteredTypes() {
    _availableTypes.clear();
    _availableTypes.addAll({
      'AreaMessage': (tiledObject) =>
          AreaMessageComponent.fromTiled(tiledObject),
    });
  }

  static ScenarioComponent fromTiled(TiledObject tiledObject) {
    final typeName = tiledObject.properties.getValue<String>('type') ?? '';
    final typeFactory = _availableTypes[typeName];
    if (typeFactory == null) {
      String factionsString =
          tiledObject.properties.getValue<String>('factions') ?? '';
      final factions = <Faction>[];
      if (factionsString.isNotEmpty) {
        final list = factionsString.split(',');
        for (final factionName in list) {
          factions.add(Faction(name: factionName.trim()));
        }
      }
      return ScenarioComponent(
        name: tiledObject.name,
        position: Vector2(tiledObject.x, tiledObject.y),
        size: Vector2(tiledObject.width, tiledObject.height),
        factions: factions,
      )..tiledObject = tiledObject;
    } else {
      return typeFactory.call(tiledObject);
    }
  }

  ScenarioComponent({
    required super.name,
    required super.position,
    required super.size,
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

      tiledObject = null;
    }
    super.onLoad();
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
