import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BackBuffer extends PositionComponent with HasPaint {
  BackBuffer(
      int width, int height, this.updateFrequency, this.saveToImageFrequency,
      [this._fadeOutOnUpdate = 0.90]) {
    this.width = width.toDouble();
    this.height = height.toDouble();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    buffer = recorder.endRecording();
    if (_fadeOutOnUpdate != null) {
      paint.color = paint.color.withOpacity(_fadeOutOnUpdate!);
    }
  }

  final double updateFrequency;
  final double saveToImageFrequency;

  double? _fadeOutOnUpdate;

  double? get fadeOutOnUpdate => _fadeOutOnUpdate;

  set fadeOutOnUpdate(double? opacity) {
    _fadeOutOnUpdate = opacity;
    if (_fadeOutOnUpdate != null) {
      paint.color = paint.color.withOpacity(_fadeOutOnUpdate!);
    } else {
      paint.color = paint.color.withOpacity(1);
    }
  }

  double dtSum = 0;
  double dtSumToImage = 0;

  late Picture buffer;

  final List<PositionComponent> _children = [];

  @override
  render(Canvas canvas) {
    canvas.drawPicture(buffer);
  }

  add(Component component) {
    if (component is! PositionComponent) {
      throw "backBuffer can work with position components only!";
    }
    _children.add(component);
  }

  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    canvas.transform(transformMatrix.storage);
    render(canvas);
    canvas.restore();
  }

  @override
  void update(double dt) async {
    dtSum += dt;
    dtSumToImage += dt;

    Picture? picUpdate;
    if (_children.isNotEmpty) {
      final recorder = PictureRecorder();
      final canvasNew = Canvas(recorder);
      for (final item in _children) {
        item.renderTree(canvasNew);
      }
      picUpdate = recorder.endRecording();
      _children.clear();
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    var imgUpdated = false;

    if (dtSum >= updateFrequency) {
      dtSum = 0;
      onBufferUpdate(canvas);
      imgUpdated = true;
    }

    if (picUpdate != null) {
      if (!imgUpdated) {
        canvas.drawPicture(buffer);
      }
      canvas.drawPicture(picUpdate);
      imgUpdated = true;
    }

    if (imgUpdated) {
      buffer = recorder.endRecording();
    }

    if (dtSumToImage >= saveToImageFrequency) {
      buffer.toImage(width.toInt(), height.toInt()).then((updatedImage) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImage(updatedImage, const Offset(0, 0), Paint());
        buffer = recorder.endRecording();
      });
      dtSumToImage = 0;
    }
  }

  @mustCallSuper
  onBufferUpdate(Canvas canvas) {
    bool saveLayer = false;
    if (_fadeOutOnUpdate != null) {
      saveLayer = true;
    }
    if (saveLayer) {
      canvas.saveLayer(null, paint);
    }
    canvas.drawPicture(buffer);
    if (saveLayer) {
      canvas.restore();
    }
  }
}
