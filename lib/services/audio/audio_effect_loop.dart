import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'howl_interop.dart';

enum EffectMode {
  standard,
  audioPool,
  webAudioAPI,
}

class AudioEffectLoop {
  AudioEffectLoop(
      {required this.effectFile,
      required this.effectDuration,
      this.effectMode = EffectMode.audioPool}) {
    print(effectFile);
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

      case EffectMode.webAudioAPI:
        _howlPlayer = Howl(HowlOptions(
          src: ['/assets/audio/$effectFile'],
          html5: false,
          preload: true,
          loop: true,
        ));
        break;
    }
  }

  EffectMode effectMode = EffectMode.audioPool;

  bool _initialized = false;
  bool _playAfterSetup = false;

  AudioPlayer? _standardPlayer;
  Future? _playStartedFuture;

  Howl? _howlPlayer;

  final Duration effectDuration;
  final String effectFile;
  bool _playing = false;
  AudioPool? _player;
  StopFunction? _playerStop;
  Timer? _replayTimer;
  double volume = 1.0;

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
      case EffectMode.webAudioAPI:
        _howlPlayer?.volume(volume);
        if (!_playing) {
          _howlPlayer?.play();
          _playing = true;
        }
        break;
    }
  }

  Future<void>? stop() {
    switch (effectMode) {
      case EffectMode.standard:
        _playStartedFuture?.then((value) {
          _standardPlayer?.pause();
        });
        return null;
        break;
      case EffectMode.audioPool:
        final future = _playerStop?.call();
        _playerStop = null;
        _playing = false;
        _replayTimer?.cancel();
        _replayTimer = null;
        return future;
        break;
      case EffectMode.webAudioAPI:
        if (_playing) {
          _howlPlayer?.pause();
          _playing = false;
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

  void dispose() {
    stop();
    _howlPlayer?.stop();
    _howlPlayer?.unload();
    _standardPlayer?.stop();
    _standardPlayer?.dispose();
    _player?.dispose();
  }
}
