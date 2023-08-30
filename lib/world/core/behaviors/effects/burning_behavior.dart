import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';

class BurningBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame> {
  BurningBehavior({
    required this.rootComponent,
    required this.burningPosition,
    this.duration,
    this.onBurningFinished,
  });

  Component rootComponent;
  Duration? duration;
  final Vector2 burningPosition;

  late final SpriteAnimationComponent fireAnimation;

  final Function? onBurningFinished;

  @override
  FutureOr<void> onLoad() {
    final animation =
        game.tilesetManager.getTile('fire', 'fire')?.spriteAnimation;
    fireAnimation = SpriteAnimationComponent(
      animation: animation,
      size: Vector2(12, 16),
      priority: 100,
    );
    fireAnimation.position = burningPosition;
    rootComponent.add(fireAnimation);
    if (duration != null) {
      Future.delayed(duration!).then((value) {
        onBurningFinished?.call();
      });
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    fireAnimation.removeFromParent();
    super.onRemove();
  }
}
