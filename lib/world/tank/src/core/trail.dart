part of tank;

class TrackTrailController extends PositionComponent {
  TrackTrailController() {
    position = Vector2(0, 0);
    priority = RenderPriority.trackTrail.priority;
  }

  init(RenderableTiledMap tileMap) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    oldTracksPic = recorder.endRecording();
    width = (tileMap.map.width * tileMap.map.tileWidth).toDouble();
    height = (tileMap.map.height * tileMap.map.tileHeight).toDouble();
    image = await oldTracksPic.toImage(width.toInt(), height.toInt());
  }

  static final newTracks = <_TrackTrailNew>[];

  static addTrack(_TrackTrailNew newTrack) {
    newTracks.add(newTrack);
  }

  late Image image;

  late Picture oldTracksPic;

  double dtSum = 0;
  double dtSumToImage = 0;

  @override
  void update(double dt) async {
    dtSum += dt;
    dtSumToImage += dt;

    Picture? newTracksPic;
    if (newTracks.isNotEmpty) {
      final paint = Paint()..color = material.Colors.black.withOpacity(0.5);
      final recorder = PictureRecorder();
      final canvasNew = Canvas(recorder);
      for (final track in newTracks) {
        canvasNew.save();
        canvasNew.translate(track.position.x, track.position.y);
        canvasNew.rotate(track.angle);
        canvasNew.drawRect(const Rect.fromLTWH(0, 13, 4, 1), paint);
        canvasNew.restore();
      }
      newTracksPic = recorder.endRecording();
      newTracks.clear();
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    var imgUpdated = false;
    if (dtSum >= 2) {
      dtSum = 0;

      canvas.saveLayer(
          null, Paint()..color = material.Colors.white.withOpacity(0.95));
      canvas.drawPicture(oldTracksPic);
      canvas.restore();
      imgUpdated = true;
    }

    if (newTracksPic != null) {
      if (!imgUpdated) {
        canvas.drawPicture(oldTracksPic);
      }
      canvas.drawPicture(newTracksPic);
      imgUpdated = true;
    }

    if (imgUpdated) {
      oldTracksPic = recorder.endRecording();
    }

    if (dtSumToImage >= 10) {
      oldTracksPic.toImage(width.toInt(), height.toInt()).then((updatedImage) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImage(updatedImage, const Offset(0, 0), Paint());
        oldTracksPic = recorder.endRecording();
      });
      dtSumToImage = 0;
    }

    super.update(dt);
  }

  @override
  render(Canvas canvas) {
    canvas.drawPicture(oldTracksPic);
  }
}

class _TrackTrailNew {
  _TrackTrailNew({required this.position, required this.angle});

  Vector2 position;
  double angle;
}
