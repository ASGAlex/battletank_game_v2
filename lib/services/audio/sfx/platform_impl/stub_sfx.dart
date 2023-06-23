import 'package:tank_game/services/audio/sfx/platform_impl/interface.dart';

class SfxImpl implements SfxInterface {
  SfxImpl({
    required this.effectName,
    this.poolSize = 2,
  });

  @override
  final String effectName;
  @override
  final int poolSize;

  @override
  void play() => throw UnimplementedError();

  @override
  void dispose() => throw UnimplementedError();
}
