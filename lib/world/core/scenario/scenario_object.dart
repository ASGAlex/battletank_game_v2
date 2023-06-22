import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_spatial_grid/flame_spatial_grid.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:intl/intl.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/faction.dart';
import 'package:tank_game/world/core/scenario/functions_registry.dart';
import 'package:tank_game/world/core/scenario/scenario_activator.dart';

class ScenarioObject extends PositionComponent
    with HasGridSupport, ActivationCallbacks, HasGameReference<MyGame> {
  factory ScenarioObject.fromTiled(TiledObject tiledObject) {
    final modal = tiledObject.properties.getValue<bool>('modal') ?? false;
    final removeWhenLeave =
        tiledObject.properties.getValue<bool>('removeWhenLeave') ?? false;
    String text = tiledObject.properties.getValue<String>('text') ?? '';

    final locale = Intl.getCurrentLocale();
    if (tiledObject.properties.has('text_$locale')) {
      text = tiledObject.properties.getValue<String>('text_$locale') ?? '';
    }

    String factionsString =
        tiledObject.properties.getValue<String>('factions') ?? '';
    final factions = <Faction>[];
    if (factionsString.isNotEmpty) {
      final list = factionsString.split(',');
      for (final factionName in list) {
        factions.add(Faction(name: factionName.trim()));
      }
    }
    return ScenarioObject(
      name: tiledObject.name,
      text: text,
      modal: modal,
      removeWhenLeave: removeWhenLeave,
      position: Vector2(tiledObject.x, tiledObject.y),
      size: Vector2(tiledObject.width, tiledObject.height),
      factions: factions,
    ).._tiledObject = tiledObject;
  }

  ScenarioObject({
    this.modal = false,
    this.removeWhenLeave = false,
    required this.name,
    this.text = '',
    required super.position,
    required super.size,
    Iterable<Faction> factions = const [],
  }) {
    this.factions.addAll(factions);
  }

  TiledObject? _tiledObject;
  final String name;
  final bool modal;
  final bool removeWhenLeave;
  final String text;
  final factions = <Faction>{};

  @override
  BoundingHitboxFactory get boundingHitboxFactory => () => ScenarioHitbox();

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
    final properties = _tiledObject?.properties;
    if (properties != null) {
      final activationName =
          properties.getValue<String>('activationCallback') ?? '';
      activationCallback = game.functionsRegistry.getFunction(activationName);

      final deactivationName =
          properties.getValue<String>('deactivationCallback') ?? '';
      deactivationCallback =
          game.functionsRegistry.getFunction(deactivationName);

      _tiledObject = null;
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

mixin ActivationCallbacks {
  bool _activated = false;

  bool get activated => _activated;

  ScenarioCallbackFunction? activationCallback;
  ScenarioCallbackFunction? deactivationCallback;

  void activatedBy(ScenarioObject object, ActorMixin other, MyGame game) {
    _activated = true;
    activationCallback?.call(object, other, game);
  }

  void deactivatedBy(ScenarioObject object, ActorMixin other, MyGame game) {
    _activated = false;
    deactivationCallback?.call(object, other, game);
  }
}
