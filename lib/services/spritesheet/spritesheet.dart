library spritesheet;

// import 'package:bonfire/bonfire.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

part 'src/base.dart';
part 'src/sheets.dart';

class SpriteSheetRegistry {
  static final SpriteSheetRegistry _singleton = SpriteSheetRegistry._internal();

  factory SpriteSheetRegistry() {
    return _singleton;
  }

  SpriteSheetRegistry._internal();

  final boom = _Boom();
  final boomBig = _BoomBig();
  final tankBasic = _TankBasic();
  final bullet = _Bullet();
  final ground = _Ground();
  final spawn = _Spawn();
  final target = _Target();
}
