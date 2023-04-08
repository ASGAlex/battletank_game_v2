import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/game.dart';

enum InteractableTrigger {
  userAction,
  activation,
}

mixin Interactor on EntityMixin {
  bool isInteractionEnabled = true;
}

class InteractableBehavior extends CollisionBehavior
    with HasGameReference<MyGame>, MessageListenerMixin<List<PlayerAction>> {
  InteractableBehavior({
    required this.action,
    required InteractableTrigger trigger,
    this.distance = 0,
    this.triggerUserAction = PlayerAction.trigger,
  }) {
    trigger = trigger;
  }

  Function action;
  late InteractableTrigger _trigger;
  double distance = 0.0;
  PlayerAction triggerUserAction;

  InteractableTrigger get trigger => _trigger;

  int _activatorsCount = 0;

  bool get activated => _activatorsCount > 0;

  set trigger(InteractableTrigger newTrigger) {
    if (_trigger == InteractableTrigger.userAction) {
      dispose();
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
    if (triggerUserAction == message && activated) {
      action.call();
    }
  }

  @override
  void onRemove() {
    dispose();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, Component other) {
    if (other is Interactor && other.isInteractionEnabled) {
      _activatorsCount++;
      if (trigger == InteractableTrigger.activation) {
        action.call();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(Component other) {
    if (other is Interactor &&
        other.isInteractionEnabled &&
        _activatorsCount > 0) {
      _activatorsCount--;
    }
    super.onCollisionEnd(other);
  }
}
