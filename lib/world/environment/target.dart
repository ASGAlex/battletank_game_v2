import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:tank_game/extensions.dart';
import 'package:tank_game/services/sound/library.dart';
import 'package:tank_game/services/spritesheet/spritesheet.dart';

import '../world.dart';

enum TargetState { alive, boom, dead }

class Target extends SpriteAnimationGroupComponent<TargetState>
    with DestroyableComponent, MyGameRef {
  Target(
      {required super.position,
      this.primary = true,
      this.protectFromEnemies = false});

  bool primary;
  bool protectFromEnemies;

  @override
  int health = 1;

  final _hitbox = RectangleHitbox();
  Duration? _boomDuration;

  @override
  Future<void>? onLoad() async {
    final alive = await SpriteSheetRegistry().target.life;
    final boom = await SpriteSheetRegistry().boomBig.animation;
    final dead = await SpriteSheetRegistry().target.dead;
    _boomDuration = boom.duration;
    size = alive.frames.first.sprite.src.size.toVector2();

    animations = {
      TargetState.alive: alive,
      TargetState.boom: boom,
      TargetState.dead: dead,
    };
    current = TargetState.alive;
    add(_hitbox);

    return super.onLoad();
  }

  @override
  onDeath() {
    remove(_hitbox);
    super.onDeath();
    current = TargetState.boom;
    final sfx = SoundLibrary().explosionPlayer;
    sfx.play();
    Future.delayed(_boomDuration!).then((value) {
      current = TargetState.dead;
      game.backBuffer?.add(this);
      removeFromParent();
    });
  }
}
