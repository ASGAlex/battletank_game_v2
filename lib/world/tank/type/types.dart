import 'package:flame/components.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';

abstract class TankType {
  double get health;

  double get damage;

  Duration get fireDelay;

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
  double get health => 1;

  @override
  double get damage => 1;

  @override
  int get speed => 55;

  @override
  Duration get fireDelay => const Duration(milliseconds: 1500);

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

class TankType1 extends TankType {
  @override
  double get health => 2;

  @override
  double get damage => 1;

  @override
  Duration get fireDelay => const Duration(milliseconds: 1250);

  @override
  int get speed => 50;

  @override
  Vector2 get size => Vector2(14, 16);

  @override
  Future<void> onLoad() async {
    animationDie = await SpriteSheetRegistry().boomBig.animation;
    animationWreck = await SpriteSheetRegistry().tankBasic1.animationWreck;
    animationRun = await SpriteSheetRegistry().tankBasic1.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic1.animationIdle;
  }
}

class TankType2 extends TankType {
  @override
  double get health => 2;

  @override
  double get damage => 1;

  @override
  Duration get fireDelay => const Duration(milliseconds: 1000);

  @override
  int get speed => 45;

  @override
  Vector2 get size => Vector2(14, 15);

  @override
  Future<void> onLoad() async {
    animationDie = await SpriteSheetRegistry().boomBig.animation;
    animationWreck = await SpriteSheetRegistry().tankBasic2.animationWreck;
    animationRun = await SpriteSheetRegistry().tankBasic2.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic2.animationIdle;
  }
}

class TankType3 extends TankType {
  @override
  double get health => 3;

  @override
  double get damage => 2;

  @override
  Duration get fireDelay => const Duration(milliseconds: 950);

  @override
  int get speed => 35;

  @override
  Vector2 get size => Vector2(14, 15);

  @override
  Future<void> onLoad() async {
    animationDie = await SpriteSheetRegistry().boomBig.animation;
    animationWreck = await SpriteSheetRegistry().tankBasic3.animationWreck;
    animationRun = await SpriteSheetRegistry().tankBasic3.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic3.animationIdle;
  }
}

class TankType4 extends TankType {
  @override
  double get health => 1;

  @override
  double get damage => 0.25;

  @override
  Duration get fireDelay => const Duration(milliseconds: 500);

  @override
  int get speed => 70;

  @override
  Vector2 get size => Vector2(14, 15);

  @override
  Future<void> onLoad() async {
    animationDie = await SpriteSheetRegistry().boomBig.animation;
    animationWreck = await SpriteSheetRegistry().tankBasic4.animationWreck;
    animationRun = await SpriteSheetRegistry().tankBasic4.animationRun;
    animationIdle = await SpriteSheetRegistry().tankBasic4.animationIdle;
  }
}
