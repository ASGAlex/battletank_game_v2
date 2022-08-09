import 'package:audioplayers/audioplayers.dart';

typedef SfxBuilder = Sfx Function();

abstract class Sfx {
  Sfx(this.fileName, [this.instances = 1]);

  final String fileName;
  String _prefix = '';

  String get fullPathToAsset => _prefix + fileName;

  final int instances;

  AudioPlayer? _controller;

  AudioPlayer? get controller => _controller;

  AssetSource? _assetSource;

  load(String prefix) {
    _prefix = prefix;
    final cache = AudioCache();
    cache.load(fullPathToAsset);
    _controller = AudioPlayer();
    _assetSource = AssetSource(fullPathToAsset);
  }

  Future play({double? volume}) async {
    final src = _assetSource;
    if (src != null) {
      return _controller?.play(src, volume: volume);
    }
  }

  pause() {
    _controller?.pause();
  }

  dispose() {
    _controller?.stop();
    _controller?.dispose();
  }
}

class SfxShort extends Sfx {
  SfxShort(super.fileName, [super.instances = 1]);

  load(String prefix) {
    super.load(prefix);
    controller?.setPlayerMode(PlayerMode.lowLatency);
  }

  @override
  Future play({double? volume}) async {
    return super.play(volume: volume).then((value) {
      _controller = AudioPlayer();
      controller?.setPlayerMode(PlayerMode.lowLatency);
    });
  }
}

class SfxLongLoop extends Sfx {
  SfxLongLoop(String fileName) : super(fileName);

  bool isPlaying = false;

  @override
  load(String prefix) {
    super.load(prefix);
    controller?.setReleaseMode(ReleaseMode.loop);
    controller?.setPlayerMode(PlayerMode.mediaPlayer);
  }

  @override
  play({double? volume}) async {
    if (isPlaying) return;

    super.play(volume: volume);
    isPlaying = true;
  }

  @override
  pause() {
    controller?.pause();
    isPlaying = false;
  }
}
