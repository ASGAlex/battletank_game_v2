import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';

extension Shortcuts on Sound {
  Sfx get movePlayer => sfx('move_player')!..controller?.setVolume(0.5);

  Sfx get moveEnemies => sfx('move_enemies')!;

  Sfx get explosionPlayer => sfx('explosion_player')!;

  Sfx get playerFireBullet => sfx('player_fire_bullet')!;

  Sfx get playerBulletWall => sfx('player_bullet_wall')!;

  Sfx get playerBulletStrongWall => sfx('player_bullet_strong_wall')!;

  Sfx get bulletStrongTank => sfx('bullet_strong_tank')!;

  Sfx get explosionEnemy => sfx('explosion_enemy')!;
}

extension Vector2Ext on Vector2 {
  Vector2 translate(double x, double y) {
    return Vector2(this.x + x, this.y + y);
  }

  Vector2 copyWith({double? x, double? y}) {
    return Vector2(x ?? this.x, y ?? this.y);
  }
}

extension StepTime on SpriteAnimation {
  Duration get duration {
    double durationMicroseconds = 0;
    for (final frame in frames) {
      durationMicroseconds += (frame.stepTime * 1000000);
    }
    return Duration(microseconds: durationMicroseconds.toInt());
  }
}
