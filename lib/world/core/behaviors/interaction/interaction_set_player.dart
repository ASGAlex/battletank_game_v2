import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/interaction/interactable.dart';
import 'package:tank_game/world/core/behaviors/player_controlled_behavior.dart';

class InteractionSetPlayer extends InteractableBehavior {
  InteractionSetPlayer({this.removeAfterSet = true})
      : super(trigger: InteractableTrigger.userAction);

  final bool removeAfterSet;

  @override
  void doTriggerAction() {
    final currentPlayerEntity = game.currentPlayer;
    if (currentPlayerEntity != null) {
      final playerControlled =
          currentPlayerEntity.findBehavior<PlayerControlledBehavior>();
      playerControlled.removeFromParent();
      currentPlayerEntity.coreState = ActorCoreState.idle;
      if (removeAfterSet) {
        currentPlayerEntity.removeFromParent();
      }

      parent.coreState = ActorCoreState.idle;
      parent.add(PlayerControlledBehavior());
      game.currentPlayer = parent;
      game.cameraComponent.follow(game.currentPlayer!);
    }
    super.doTriggerAction();
  }
}
