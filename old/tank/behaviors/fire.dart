import '../core/base_tank.dart';

typedef FireFunc = bool Function();

class FireController {
  FireController(this.parent) : _fire = parent.onFire;

  FireFunc _fire;

  Tank parent;

  bool _retryFire = false;

  fireASAP() {
    final success = fireIfCan();
    _retryFire = !success;
  }

  onWeaponReloaded() {
    if (_retryFire) {
      fireASAP();
    }
  }

  bool fireIfCan() => _fire.call();
}
