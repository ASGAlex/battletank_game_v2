import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/components/scenario_event_emitter_mixin.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';

typedef ScenarioEventFactory = ScenarioEvent Function({
  required Component emitter,
  required String name,
  dynamic data,
});

class AreaEventComponent extends ScenarioComponent<AreaEventComponent>
    with ScenarioEventEmitter {
  static final _availableEvents = <String, ScenarioEventFactory>{};

  static registerEvent(String name, ScenarioEventFactory factory) {
    _availableEvents[name] = factory;
  }

  static unregisterEvent(String name) {
    _availableEvents.remove(name);
  }

  static restoreDefaults() {
    _availableEvents.clear();
    _availableEvents.addAll({}); // TODO: default scripts here
  }

  AreaEventComponent({super.tiledObject});

  late final String eventName;

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      try {
        eventName = properties.getValue<String>('eventName') ?? '';
      } catch (_) {}
    }
    super.onLoad();
  }

  @override
  void activatedBy(AreaEventComponent scenario, ActorMixin other, MyGame game) {
    final eventBuilder = _availableEvents[eventName];
    if (eventBuilder != null) {
      final event = eventBuilder(
          emitter: other,
          name: eventName,
          data: AreaEventData(true, tiledObject?.properties));
      scenarioEvent(event);
      super.activatedBy(scenario, other, game);
    }
  }

  @override
  void deactivatedBy(
      AreaEventComponent scenario, ActorMixin other, MyGame game) {
    final eventBuilder = _availableEvents[eventName];
    if (eventBuilder != null) {
      final event = eventBuilder(
        emitter: other,
        name: eventName,
        data: AreaEventData(false, tiledObject?.properties),
      );
      scenarioEvent(event);
      super.deactivatedBy(scenario, other, game);
    }
  }
}

@immutable
class AreaEventData {
  final bool activated;
  final CustomProperties? properties;

  const AreaEventData(this.activated, this.properties);
}
