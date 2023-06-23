abstract interface class SfxInterface {
  SfxInterface({
    required this.effectName,
    this.poolSize = 2,
  });

  final String effectName;
  final int poolSize;

  void play();

  void dispose();
}
