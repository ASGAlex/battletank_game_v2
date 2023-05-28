import 'package:flame/sprite.dart';

class ConfigurableAnimation extends SpriteAnimation {
  ConfigurableAnimation(SpriteAnimation animation)
      : super(animation.frames, loop: animation.loop);

  void Function()? onComplete;

  @override
  SpriteAnimationTicker ticker() {
    final ticker = super.ticker();
    ticker.onComplete = onComplete;
    return ticker;
  }
}
