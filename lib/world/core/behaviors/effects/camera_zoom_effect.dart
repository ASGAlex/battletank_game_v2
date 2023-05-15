import 'dart:async';

import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';

class CameraZoomEffect extends Effect {
  CameraZoomEffect(this.targetZoom, super.controller);

  final double targetZoom;
  double _initialZoom = 0;

  Viewfinder get viewfinder => parent as Viewfinder;

  @override
  FutureOr<void> onLoad() {
    assert(parent is Viewfinder);
    return super.onLoad();
  }

  @override
  void onStart() {
    _initialZoom = viewfinder.zoom;
  }

  @override
  void apply(double progress) {
    final diff = (targetZoom - _initialZoom) * progress;
    viewfinder.zoom = _initialZoom + diff;
  }
}
