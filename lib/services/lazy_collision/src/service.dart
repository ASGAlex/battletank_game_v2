part of lazy_collision;

class LazyCollisionsService extends LongRunningIsolateClient {
  LazyCollisionsService();

  final _processedLayers = <String, Duration>{};

  @override
  run(
      [Map<String, Duration> layers = const {
        'default': Duration(milliseconds: 500)
      }]) async {
    _processedLayers.addAll(layers);
    await runMain(_workerIsolateMain);
    final futures = <Future>[];
    for (final entry in layers.entries) {
      futures.add(addLayer(entry.key));
    }
    await Future.wait(futures);

    for (final entry in _processedLayers.entries) {
      _periodicalCheck(entry.key, entry.value);
    }
  }

  static _Worker createWorker(SendPort sendPort, ReceivePort receivePort,
          [String debugLabel = '']) =>
      _Worker(sendPort, receivePort, debugLabel);

  void _periodicalCheck(
      [String layer = 'default',
      Duration duration = const Duration(milliseconds: 500)]) {
    if (!init && !debug) return;
    Future.delayed(duration).then((value) {
      sendMessage(
          _Message(action: WorkerAction.collisionsUpdate, layer: layer));
      _periodicalCheck(layer, duration);
    });
  }

  Future<bool> addLayer(String layer,
      [Duration checkDuration = const Duration(milliseconds: 500)]) async {
    sendMessage(_Message(action: WorkerAction.layerInit, layer: layer));
    return await nextEvent();
  }

  Future<bool> removeLayer(String layer) async {
    sendMessage(_Message(action: WorkerAction.layerInit, layer: layer));
    return await nextEvent();
  }

  Future<int> addHitbox(
      {required Vector2 position,
      required Vector2 size,
      CollisionType type = CollisionType.passive,
      String? layer}) async {
    final msg = _Message(
        action: WorkerAction.hitboxAdd,
        type: type,
        size: size.clone(),
        position: position.clone(),
        layer: layer);
    sendMessage(msg);

    return await nextEvent();
  }

  void updateHitbox(
      {required int id,
      required Vector2 position,
      required Vector2 size,
      CollisionType type = CollisionType.passive,
      String? layer}) async {
    sendMessage(_Message(
        action: WorkerAction.hitboxUpdate,
        id: id,
        type: type,
        size: size.clone(),
        position: position.clone(),
        layer: layer));
  }

  void removeHitbox(int id, [String? layer]) async {
    sendMessage(
        _Message(action: WorkerAction.hitboxRemove, id: id, layer: layer));
  }

  Future<int> getCollisionsCount(int id, [String? layer]) async {
    final msg =
        _Message(action: WorkerAction.collisionsGetCount, id: id, layer: layer);
    sendMessage(msg);
    return await nextEvent();
  }
}
