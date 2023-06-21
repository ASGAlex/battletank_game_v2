import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

class AudioEffectLoop {
  AudioEffectLoop({required this.effectFile, required this.effectDuration}) {
    FlameAudio.createPool(effectFile, maxPlayers: 2).then((value) {
      _player = value;
    });
  }

  final Duration effectDuration;
  final String effectFile;
  bool _playing = false;
  late AudioPool _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;

  void play() {
    if (!_playing) {
      _play();
      _replayTimer ??= Timer.periodic(effectDuration, (timer) {
        _play();
      });
    }
  }

  void stop() {
    _playerStop?.call();
    _playerStop = null;
    _playing = false;
    _replayTimer?.cancel();
    _replayTimer = null;
  }

  void _play() {
    _playing = true;
    _player.start().then((value) {
      _playerStop = value;
    });
  }

  void dispose() {
    _player.dispose();
  }
}
