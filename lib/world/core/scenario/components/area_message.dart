import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/game/scenario/bottom_message.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/components/has_text_message_mixin.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class AreaMessageComponent extends ScenarioComponent<AreaMessageComponent>
    with HasTextMessage<AreaMessageComponent> {
  late final bool modal;

  AreaMessageComponent({
    bool? modal = false,
    super.tiledObject,
    String text = '',
  }) {
    if (tiledObject == null) {
      this.text = text;
    }
    if (modal != null) {
      this.modal = modal;
    }
  }

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      try {
        modal = properties.getValue<bool>('modal') ?? false;
      } catch (_) {}

      var text = properties.getValue<String>('text') ?? '';
      final locale = Intl.getCurrentLocale();
      text = properties.getValue<String>('text_$locale') ?? text;
      this.text = text;
    }
    super.onLoad();
  }

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
    game.hideScenarioMessage();
    super.deactivatedBy(scenario, other, game);
  }
}
