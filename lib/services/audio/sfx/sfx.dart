import 'package:tank_game/services/audio/sfx/platform_impl/interface.dart';

import 'platform_impl/stub_sfx.dart'
    if (dart.library.io) 'platform_impl/io_sfx.dart'
    if (dart.library.html) 'platform_impl/web_sfx.dart';

class Sfx implements SfxInterface {
  Sfx({
    required String effectName,
    int poolSize = 2,
  }) : _sfxImpl = SfxImpl(effectName: effectName, poolSize: poolSize);

  final SfxImpl _sfxImpl;

  @override
  void dispose() => _sfxImpl.dispose();

  @override
  String get effectName => _sfxImpl.effectName;

  @override
  void play() => _sfxImpl.play();

  @override
  int get poolSize => _sfxImpl.poolSize;
}
