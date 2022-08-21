import 'package:audioplayers/audioplayers.dart';

class SoundLibrary {
  static const music = <String>[
    'move_player.m4a',
    'move_enemies.m4a',
  ];

  static const sfx = <String>[
    'explosion_player.m4a',
    'explosion_enemy.m4a',
    'player_fire_bullet.m4a',
    'player_bullet_wall.m4a',
    'player_bullet_strong_wall.m4a',
    'bullet_strong_tank.m4a'
  ];

  static loadSounds() {
    AudioPlayer.global.changeLogLevel(LogLevel.info);
    AudioCache.instance.loadAll(sfx.map((e) => 'audio/sfx/$e').toList());
    AudioCache.instance.loadAll(music.map((e) => 'audio/music/$e').toList());
  }

  static Future<AudioPlayer> createSfxPlayer(String fileName,
      {String? playerId}) async {
    final player = AudioPlayer(playerId: playerId);
    await player.setSource(AssetSource('audio/sfx/$fileName'));
    player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }

  static Future<AudioPlayer> createMusicPlayer(String fileName,
      {String? playerId}) async {
    final player = AudioPlayer(playerId: playerId);
    await player.setSource(AssetSource('audio/music/$fileName'));
    return player;
  }
}

class DistantSfxPlayer {
  DistantSfxPlayer(this._distanceOfSilence);

  /// No sounds on this distance and above
  double _distanceOfSilence;

  double _actualDistance = 0;

  double _volume = 1;

  set actualDistance(double distance) {
    _actualDistance = distance;
    _updateVolume();
  }

  set distanceOfSilence(double distance) {
    _distanceOfSilence = distance;
    _updateVolume();
  }

  _updateVolume() {
    _volume = 1 - (_actualDistance / _distanceOfSilence);
  }

  play(AudioPlayer sfx) async {
    if (_volume > 0) {
      sfx.setVolume(_volume);
      sfx.resume();
    }
  }
}
