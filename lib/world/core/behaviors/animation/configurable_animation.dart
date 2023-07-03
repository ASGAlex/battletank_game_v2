import 'package:flame/sprite.dart';

class ConfigurableAnimation extends SpriteAnimation {
  ConfigurableAnimation(SpriteAnimation animation)
      : super(animation.frames, loop: animation.loop);

  void Function()? onComplete;

  @override
  SpriteAnimationTicker createTicker() {
    final ticker = super.createTicker();
    ticker.onComplete = onComplete;
    return ticker;
  }
}
