import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/game/scenario/bottom_message.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class AreaMessageComponent extends ScenarioComponent<AreaMessageComponent> {
  final bool removeWhenLeave;
  final String text;
  final bool modal;

  factory AreaMessageComponent.fromTiled(TiledObject tiledObject) {
    final modal = tiledObject.properties.has('modal')
        ? tiledObject.properties.getValue<bool>('modal') ?? false
        : false;

    final removeWhenLeave = tiledObject.properties.has('removeWhenLeave')
        ? tiledObject.properties.getValue<bool>('removeWhenLeave') ?? false
        : false;
    String text = tiledObject.properties.has('text')
        ? tiledObject.properties.getValue<String>('text') ?? ''
        : '';
    final locale = Intl.getCurrentLocale();
    if (tiledObject.properties.has('text_$locale')) {
      text = tiledObject.properties.getValue<String>('text_$locale') ?? '';
    }
    final coreObject = ScenarioComponent.parseTiledObject(tiledObject);
    return AreaMessageComponent(
      name: coreObject.name,
      position: coreObject.position,
      size: coreObject.size,
      removeWhenLeave: removeWhenLeave,
      modal: modal,
      text: text,
    )..tiledObject = coreObject.tiledObject;
  }

  AreaMessageComponent({
    this.modal = false,
    required super.name,
    required super.position,
    required super.size,
    this.removeWhenLeave = false,
    this.text = '',
  });

  @override
  void activatedBy(
      AreaMessageComponent scenario, ActorMixin other, MyGame game) {
    super.activatedBy(scenario, other, game);

    final text = scenario.text;
    if (text.isNotEmpty) {
      game.showScenarioMessage(TalkDialog(
        // nextOnTap: true,
        // nextOnAnyKey: true,
        says: [
          Say(
            text: [TextSpan(text: scenario.text)],
          ),
        ],
      ));
    }
  }

  @override
  void deactivatedBy(
      AreaMessageComponent scenario, ActorMixin other, MyGame game) {
    super.deactivatedBy(scenario, other, game);
    game.hideScenarioMessage();
    if (scenario.removeWhenLeave) {
      removeFromParent();
    }
  }
}
