import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

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

  static Soundpool? pool;

  static final Map<String, int> _loadedSoundIds = {};

  static loadSounds() async {
    if (Platform.isAndroid) {
      pool = Soundpool(streamType: StreamType.music, maxStreams: 100);
      for (var element in sfx) {
        _loadedSoundIds[element] = await rootBundle
            .load("assets/audio/sfx/$element")
            .then((ByteData soundData) {
          return pool!.load(soundData);
        });
      }
      for (var element in music) {
        _loadedSoundIds[element] = await rootBundle
            .load("assets/audio/music/$element")
            .then((ByteData soundData) {
          return pool!.load(soundData);
        });
      }
    } else {
      AudioPlayer.global.changeLogLevel(LogLevel.info);
      AudioPlayer.global.setGlobalAudioContext(AudioContext(
          android: AudioContextAndroid(
              audioFocus: AndroidAudioFocus.gainTransientExclusive,
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.game),
          iOS: AudioContextIOS(
              defaultToSpeaker: true,
              category: AVAudioSessionCategory.multiRoute,
              options: [])));
      AudioCache.instance.loadAll(sfx.map((e) => 'audio/sfx/$e').toList());
      AudioCache.instance.loadAll(music.map((e) => 'audio/music/$e').toList());
    }
  }

  static Future<AudioPlayer> createSfxPlayer(String fileName,
      {String? playerId}) async {
    if (Platform.isWindows) {
      final player = AudioPlayer(playerId: playerId);
      await player.setSource(AssetSource('audio/sfx/$fileName'));
      player.setPlayerMode(PlayerMode.lowLatency);
      return player;
    } else {
      final soundId = _loadedSoundIds[fileName];
      return CrossPlatformPlayer()..soundId = soundId;
    }
  }

  static Future<AudioPlayer> createMusicPlayer(String fileName,
      {String? playerId}) async {
    final player = AudioPlayer(playerId: playerId);
    await player.setSource(AssetSource('audio/music/$fileName'));
    return player;
  }

  static dispose() {
    _loadedSoundIds.clear();
    pool?.dispose();
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

class CrossPlatformPlayer extends AudioPlayer {
  int? soundId;
  var _state = PlayerState.stopped;

  @override
  PlayerState get state {
    if (Platform.isAndroid) {
      return _state;
    } else {
      return super.state;
    }
  }

  @override
  Future setVolume(double volume) async {
    if (Platform.isAndroid) {
      await SoundLibrary.pool?.setVolume(soundId: soundId, volume: volume);
      return true;
    } else if (soundId != null) {
      return setVolume(volume);
    }
    return false;
  }

  @override
  Future resume() async {
    if (Platform.isAndroid) {
      _state = PlayerState.playing;
      await SoundLibrary.pool?.play(soundId!);
      return true;
    } else if (soundId != null) {
      return super.resume();
    }
    return false;
  }

  @override
  Future pause() async {
    if (Platform.isAndroid) {
      _state = PlayerState.paused;
      await SoundLibrary.pool?.stop(soundId!);
      return true;
    } else if (soundId != null) {
      return super.pause();
    }
    return false;
  }
}
