import 'package:audioplayers/audioplayers.dart';
import 'package:tank_game/packages/sound/lib/sound.dart';

class SoundLibrary {
  static final SoundLibrary _instance = SoundLibrary._();

  SoundLibrary._();

  factory SoundLibrary() {
    return _instance;
  }

  Sfx get movePlayer => Sound().sfx('move_player')!..controller?.setVolume(0.5);

  Sfx get moveEnemies => Sound().sfx('move_enemies')!;

  Sfx get explosionPlayer => Sound().sfx('explosion_player')!;

  Sfx get playerFireBullet => Sound().sfx('player_fire_bullet')!;

  Sfx get playerBulletWall => Sound().sfx('player_bullet_wall')!;

  Sfx get playerBulletStrongWall => Sound().sfx('player_bullet_strong_wall')!;

  Sfx get bulletStrongTank => Sound().sfx('bullet_strong_tank')!;

  Sfx get explosionEnemy => Sound().sfx('explosion_enemy')!;

  playIntro() => Sound().playMusic('intro.m4a');

  init() {
    AudioPlayer.global.changeLogLevel(LogLevel.info);
    final sound = Sound();
    final sfxList = [
      () => SfxLongLoop('move_player.m4a'),
      () => SfxLongLoop('move_enemies.m4a'),
      () => SfxShort('explosion_player.m4a', 1),
      () => SfxShort('explosion_enemy.m4a', 1),
      () => SfxShort('player_fire_bullet.m4a', 1),
      () => SfxShort('player_bullet_wall.m4a', 1),
      () => SfxShort('player_bullet_strong_wall.m4a', 1),
      () => SfxShort('bullet_strong_tank.m4a', 1),
    ];
    sound.init(sfxList);
  }
}
