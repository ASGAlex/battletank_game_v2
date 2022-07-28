import 'sfx.dart';

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

  play(Sfx sfx) async {
    if (_volume > 0) {
      sfx.controller?.setVolume(_volume);
      sfx.play();
    }
  }
}
