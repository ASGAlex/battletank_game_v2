import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

class AudioEffectLoop {
  static bool standard = false;

  AudioEffectLoop({required this.effectFile, required this.effectDuration}) {
    if (standard) {
      FlameAudio.loop(effectFile).then((value) {
        value.pause();
        _standardPlayer = value;
        _initialized = true;
        if (_playAfterSetup) {
          play();
        }
      });
    } else {
      FlameAudio.createPool(effectFile, maxPlayers: 2).then((value) {
        _player = value;
        _initialized = true;
        if (_playAfterSetup) {
          play();
        }
      });
    }
  }

  bool _initialized = false;
  bool _playAfterSetup = false;

  AudioPlayer? _standardPlayer;

  final Duration effectDuration;
  final String effectFile;
  bool _playing = false;
  AudioPool? _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;
  double volume = 1.0;

  void play() {
    if (standard) {
      _standardPlayer?.setVolume(volume);
      _standardPlayer?.resume();
    } else {
      if (!_playing) {
        _play();
        _replayTimer ??= Timer.periodic(effectDuration, (timer) {
          _play();
        });
      }
    }
  }

  Future<void>? stop() {
    if (standard) {
      _standardPlayer?.pause();
      return null;
    } else {
      final future = _playerStop?.call();
      _playerStop = null;
      _playing = false;
      _replayTimer?.cancel();
      _replayTimer = null;
      return future;
    }
  }

  void _play() {
    _playing = true;
    if (_initialized) {
      _player?.start(volume: volume).then((value) {
        _playerStop = value;
      });
    } else {
      _playAfterSetup = true;
    }
  }

  void dispose() {
    stop();
    _standardPlayer?.stop();
    _standardPlayer?.dispose();
    _player?.dispose();
  }
}
