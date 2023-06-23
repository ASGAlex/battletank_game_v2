import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioEffectLoop {
  AudioEffectLoop({required this.effectFile, required this.effectDuration}) {
    if (kIsWeb) {
    } else {
      FlameAudio.createPool(effectFile, maxPlayers: 2).then((value) {
        _player = value;
      });
    }
  }

  final Duration effectDuration;
  final String effectFile;
  bool _playing = false;
  late AudioPool _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;
  double volume = 1.0;

  void play() {
    if (kIsWeb) {
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
    if (kIsWeb) {
      return null;
    } else {
      final future = _playerStop?.call().catchError((_) {});
      _playerStop = null;
      _playing = false;
      _replayTimer?.cancel();
      _replayTimer = null;
      return future;
    }
  }

  void _play() {
    _playing = true;
    _player.start(volume: volume).then((value) {
      _playerStop = value;
    }).catchError((_) {});
    ;
  }

  void dispose() {
    stop();
    _player.dispose().catchError((_) {});
  }
}
