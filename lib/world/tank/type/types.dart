import 'package:flame/components.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';

abstract class TankType {
  int get health;

  int get speed;

  Vector2 get size;

  late SpriteAnimation animationDie;

  late SpriteAnimation animationIdle;

  late SpriteAnimation animationRun;

  late SpriteAnimation animationWreck;

  Future<void> onLoad();
}

class TankType0 extends TankType {
  @override
  int get health => 1;

  @override
  int get speed => 50;

  @override
  Vector2 get size => Vector2(14, 14);

  @override
  Future<void> onLoad() async {
    animationDie = await SpriteSheetRegistry().boomBig.animation;
    animationWreck = await SpriteSheetRegistry().tankBasic.animationWreck;
    animationRun = await SpriteSheetRegistry().tankBasic.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic.animationIdle;
  }
}
