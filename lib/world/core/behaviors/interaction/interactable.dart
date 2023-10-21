import 'package:flame/components.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/packages/behaviors/lib/flame_behaviors.dart';
import 'package:tank_game/world/core/behaviors/collision_behavior.dart';

enum InteractableTrigger {
  userAction,
  activation,
}

mixin Interactor on EntityMixin {
  bool isInteractionEnabled = false;
}

class InteractableBehavior extends CollisionBehavior
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  InteractableBehavior({
    this.action,
    required InteractableTrigger trigger,
    this.triggerUserAction = PlayerAction.triggerE,
  }) {
    _trigger = trigger;
    this.trigger = trigger;
  }

  Function? action;
  late InteractableTrigger _trigger;
  PlayerAction triggerUserAction;

  InteractableTrigger get trigger => _trigger;

  int _activatorsCount = 0;

  bool get activated => _activatorsCount > 0;

  set trigger(InteractableTrigger newTrigger) {
    if (_trigger == InteractableTrigger.userAction) {
      disposeListener();
    }
    _trigger = newTrigger;
    if (_trigger == InteractableTrigger.userAction) {
      listenProvider(game.inputEventsHandler.messageProvider);
      priority = -1;
    }
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    if (trigger != InteractableTrigger.userAction) return;
    if (message.contains(triggerUserAction) && activated) {
      doTriggerAction();
    }
  }

  void doTriggerAction() {
    action?.call();
  }

  @override
  void onRemove() {
    disposeListener();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Interactor && (other as Interactor).isInteractionEnabled) {
      _activatorsCount++;
      if (trigger == InteractableTrigger.activation) {
        doTriggerAction();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Interactor &&
        (other as Interactor).isInteractionEnabled &&
        _activatorsCount > 0) {
      _activatorsCount--;
    }
    super.onCollisionEnd(other);
  }
}
