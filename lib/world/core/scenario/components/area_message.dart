import 'package:tank_game/game.dart';
import 'package:tank_game/ui/game/scenario/message_widget.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/scenario/components/has_text_message_mixin.dart';
import 'package:tank_game/world/core/scenario/scenario_component.dart';

class AreaMessageComponent extends ScenarioComponent<AreaMessageComponent>
    with HasTextMessage<AreaMessageComponent> {
  late final bool modal;
  late final String text;
  late final bool split;

  AreaMessageComponent({
    bool? modal = false,
    super.tiledObject,
    String text = '',
    bool? split,
  }) {
    if (tiledObject == null) {
      this.text = text;
    }
    if (modal != null) {
      this.modal = modal;
    }
    if (split != null) {
      this.split = split;
    }
  }

  @override
  void onLoad() {
    final properties = tiledObject?.properties;
    if (properties != null) {
      try {
        modal = properties.getValue<bool>('modal') ?? false;
      } catch (_) {}

      try {
        split = properties.getValue<bool>('split') ?? false;
      } catch (_) {}

      text = getTextMessage('text');
    }
    super.onLoad();
  }

  @override
  void activatedBy(
      AreaMessageComponent scenario, ActorMixin other, MyGame game) {
    super.activatedBy(scenario, other, game);

    final text = scenario.text;
    if (text.isNotEmpty) {
      if (split) {
        final says = text.split('\n').toList();
        game.showScenarioMessage(MessageWidget(
          // nextOnTap: true,
          // nextOnAnyKey: true,
          texts: says,
          provider: game.inputEventsHandler.messageProvider,
        ));
      } else {
        game.showScenarioMessage(MessageWidget(
          // nextOnTap: true,
          // nextOnAnyKey: true,
          texts: [scenario.text],
          provider: game.inputEventsHandler.messageProvider,
        ));
      }
    }
  }

  @override
  void deactivatedBy(
      AreaMessageComponent scenario, ActorMixin other, MyGame game) {
    game.hideScenarioMessage();
    super.deactivatedBy(scenario, other, game);
  }
}
