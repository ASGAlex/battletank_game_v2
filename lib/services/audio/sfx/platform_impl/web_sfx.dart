import 'package:tank_game/services/audio/howl_interop.dart';
import 'package:tank_game/services/audio/sfx/platform_impl/interface.dart';

class SfxImpl implements SfxInterface {
  SfxImpl({
    required this.effectName,
    this.poolSize = 2,
  }) {
    _howlPlayer = Howl(HowlOptions(
      src: ['${Uri.base}/assets/audio/$effectName'],
      html5: false,
      preload: true,
      loop: false,
    ));
  }

  Howl? _howlPlayer;

  @override
  final String effectName;
  @override
  final int poolSize;

  @override
  void play() {
    _howlPlayer?.play();
  }

  @override
  void dispose() {
    _howlPlayer?.unload();
  }
}
