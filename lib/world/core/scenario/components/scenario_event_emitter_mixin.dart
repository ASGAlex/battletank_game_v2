import 'package:flame/components.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';

mixin ScenarioEventEmitter<T extends ScenarioEvent>
    on HasGameReference<MyGame> {
  void scenarioEvent(T event) {
    game.scenarioEventProvider.sendMessage(event);
  }
}
