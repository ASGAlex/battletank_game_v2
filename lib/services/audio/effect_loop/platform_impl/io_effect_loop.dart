import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'interface.dart';

class AudioEffectLoopImpl implements AudioEffectLoopInterface {
  AudioEffectLoopImpl(
      {required this.effectFile,
      required this.effectDuration,
      this.effectMode = EffectMode.audioPool}) {
    switch (effectMode) {
      case EffectMode.standard:
        FlameAudio.loop(effectFile).then((value) {
          value.pause();
          _standardPlayer = value;
          _initialized = true;
          if (_playAfterSetup) {
            play();
          }
        });
        break;
      case EffectMode.audioPool:
        FlameAudio.createPool(effectFile, maxPlayers: 2).then((value) {
          _player = value;
          _initialized = true;
          if (_playAfterSetup) {
            play();
          }
        });
        break;
    }
  }

  bool _initialized = false;
  bool _playAfterSetup = false;

  AudioPlayer? _standardPlayer;
  Future? _playStartedFuture;

  @override
  final Duration effectDuration;

  @override
  final String effectFile;
  bool _playing = false;
  AudioPool? _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;

  @override
  void dispose() {
    stop();
    _standardPlayer?.stop();
    _standardPlayer?.dispose();
    _player?.dispose();
  }

  @override
  void play() {
    switch (effectMode) {
      case EffectMode.standard:
        _standardPlayer?.setVolume(volume).then((value) {
          if (_standardPlayer?.state != PlayerState.playing) {
            _playStartedFuture = _standardPlayer?.resume();
          }
        });
        break;
      case EffectMode.audioPool:
        if (!_playing) {
          _play();
          _replayTimer ??= Timer.periodic(effectDuration, (timer) {
            _play();
          });
        }
        break;
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

  @override
  Future<void>? stop() {
    switch (effectMode) {
      case EffectMode.standard:
        _playStartedFuture?.then((value) {
          _standardPlayer?.pause();
        });
        break;
      case EffectMode.audioPool:
        if (_playing) {
          final future = _playerStop?.call();
          _playerStop = null;
          _playing = false;
          _replayTimer?.cancel();
          _replayTimer = null;
          return future;
        }
        break;
    }
    return null;
  }

  @override
  EffectMode effectMode;

  @override
  double volume = 1.0;
}
