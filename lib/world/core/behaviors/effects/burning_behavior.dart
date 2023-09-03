import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/world/core/actor.dart';
import 'package:tank_game/world/core/behaviors/core_behavior.dart';
import 'package:tank_game/world/core/behaviors/effects/smoke_behavior.dart';

class BurningBehavior extends CoreBehavior<ActorMixin>
    with HasGameReference<MyGame> {
  BurningBehavior({
    required this.rootComponent,
    required this.burningPosition,
    this.duration,
    this.onBurningFinished,
    this.onRemoveCallback,
  });

  Component rootComponent;
  Duration? duration;
  final Vector2 burningPosition;

  late final SpriteAnimationComponent fireAnimation;
  late final SmokeComponent smoke;

  final Function? onBurningFinished;
  final Function? onRemoveCallback;

  @override
  FutureOr<void> onLoad() {
    final animation =
        game.tilesetManager.getTile('fire', 'fire')?.spriteAnimation;
    final fireSize = Vector2(12, 16);
    fireAnimation = SpriteAnimationComponent(
      animation: animation,
      size: fireSize,
      priority: 100,
    );
    fireAnimation.position = burningPosition;
    smoke = SmokeComponent(
      rootComponent,
      parentPosition:
          burningPosition.translated(fireSize.x / 2, fireSize.y / 2),
      parentSize: fireSize,
    );
    rootComponent.add(fireAnimation);
    rootComponent.add(smoke);

    if (duration != null) {
      Future.delayed(duration!).then((value) {
        onBurningFinished?.call();
        smoke.isEnabled = true;
        Future.delayed(const Duration(seconds: 10)).then((value) {
          fireAnimation.removeFromParent();
          Future.delayed(const Duration(seconds: 60)).then((value) {
            removeFromParent();
          });
        });
      });
    }
    return super.onLoad();
  }

  @override
  void onRemove() {
    onRemoveCallback?.call();
    fireAnimation.removeFromParent();
    smoke.removeFromParent();
    super.onRemove();
  }
}
