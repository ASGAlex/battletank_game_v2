part of tank;

class TrackTrailController extends PositionComponent {
  TrackTrailController() {
    position = Vector2(0, 0);
    priority = RenderPriority.trackTrail.priority;
  }

  init(RenderableTiledMap tileMap) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final picture = recorder.endRecording();
    width = (tileMap.map.width * tileMap.map.tileWidth).toDouble();
    height = (tileMap.map.height * tileMap.map.tileHeight).toDouble();
    image = await picture.toImage(width.toInt(), height.toInt());
  }

  static final newTracks = <_TrackTrailNew>[];

  static addTrack(_TrackTrailNew newTrack) {
    newTracks.add(newTrack);
  }

  late Image image;

  double dtSum = 0;

  @override
  void update(double dt) async {
    dtSum += dt;

    Picture? picture;
    if (newTracks.isNotEmpty) {
      final paint = Paint()..color = material.Colors.black.withOpacity(0.5);
      final recorder = PictureRecorder();
      final canvasNew = Canvas(recorder);
      for (final track in newTracks) {
        canvasNew.save();
        canvasNew.translate(track.position.x, track.position.y);
        canvasNew.rotate(track.angle);
        canvasNew.drawRect(const Rect.fromLTRB(0, 0, 1, 4), paint);
        canvasNew.restore();
      }
      picture = recorder.endRecording();
      newTracks.clear();
    }

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    var imgUpdated = false;
    if (dtSum >= 1) {
      dtSum = 0;
      canvas.drawImage(
          image,
          const Offset(0, 0),
          Paint()
            ..color = material.Colors.white.withOpacity(0.99)
            ..filterQuality = FilterQuality.low);
      imgUpdated = true;
    }

    if (picture != null) {
      if (!imgUpdated) {
        canvas.drawImage(image, const Offset(0, 0),
            Paint()..filterQuality = FilterQuality.low);
      }
      canvas.drawPicture(picture);
      imgUpdated = true;
    }

    if (imgUpdated) {
      final pic = recorder.endRecording();
      image = await pic.toImage(width.toInt(), height.toInt());
    }

    super.update(dt);
  }

  @override
  render(Canvas canvas) {
    canvas.drawImage(
        image, const Offset(0, 0), Paint()..filterQuality = FilterQuality.low);
    super.render(canvas);
  }
}

class _TrackTrailNew {
  _TrackTrailNew({required this.position, required this.angle});

  Vector2 position;
  double angle;
}
