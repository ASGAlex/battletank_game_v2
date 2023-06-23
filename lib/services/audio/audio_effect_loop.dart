import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioEffectLoop {
  AudioEffectLoop({required this.effectFile, required this.effectDuration}) {
    standard = kIsWeb;
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

  bool standard = false;

  bool _initialized = false;
  bool _playAfterSetup = false;

  AudioPlayer? _standardPlayer;
  Future? _playStartedFuture;

  final Duration effectDuration;
  final String effectFile;
  bool _playing = false;
  AudioPool? _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;
  double volume = 1.0;

  void play() {
    if (standard) {
      _standardPlayer?.setVolume(volume).then((value) {
        if (_standardPlayer?.state != PlayerState.playing) {
          _playStartedFuture = _standardPlayer?.resume();
        }
      });
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
      _playStartedFuture?.then((value) {
        _standardPlayer?.pause();
      });
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
