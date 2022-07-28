import 'dart:isolate';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:tank_game/packages/long_running_isolate/lib/long_running_isolate.dart';

enum WorkerAction {
  layerInit,
  layerRemove,
  collisionsUpdate,
  collisionsGetCount,
  hitboxAdd,
  hitboxUpdate,
  hitboxRemove
}

class Message {
  Message(
      {required this.action,
      this.id,
      this.position,
      this.type,
      this.size,
      String? layer})
      : layer = layer ?? 'default' {
    switch (action) {
      case WorkerAction.collisionsUpdate:
        break;

      case WorkerAction.layerRemove:
      case WorkerAction.layerInit:
        if (layer == '') {
          throw 'Layer should have a name';
        }
        break;
      case WorkerAction.hitboxRemove:
      case WorkerAction.hitboxUpdate:
      case WorkerAction.collisionsGetCount:
        if (id == null) {
          throw 'id should be defined';
        }
        break;
      case WorkerAction.hitboxAdd:
        if (position == null || size == null) {
          throw 'position and size required';
        }
        type ??= CollisionType.passive;
        break;
    }
  }

  final String? layer;
  int? id;
  Vector2? position;
  Vector2? size;
  CollisionType? type;
  WorkerAction action;
}

class Worker extends LongRunningIsolateServer {
  Worker(super.sendPort, super.receivePort, [this.debugLabel = '']);

  final String debugLabel;

  final Map<String, Map<int, Rectangle<double>>> _hitboxes = {};
  final Map<String, List<int>> _activeHitboxes = {};

  final Map<String, Map<int, int>> _calculatedResults = {};

  final _index = <String, int>{};

  @override
  processMessage(message) {
    if (message is Message) {
      switch (message.action) {
        case WorkerAction.collisionsUpdate:
          _collisionsUpdate(message.layer ?? 'default');
          break;
        case WorkerAction.collisionsGetCount:
          sendResponse(_calculatedResults[message.layer]?[message.id] ?? 0);
          break;
        case WorkerAction.hitboxAdd:
          _hitboxAdd(message);
          break;
        case WorkerAction.hitboxUpdate:
          _hitboxUpdate(message);
          break;
        case WorkerAction.hitboxRemove:
          _hitboxRemove(message);
          break;
        case WorkerAction.layerInit:
          _layerInit(message.layer!);
          break;
        case WorkerAction.layerRemove:
          _layerRemove(message.layer!);
          break;
      }
    }
  }

  _layerInit(String layer) {
    if (_index[layer] == null) {
      _index[layer] = 0;
    }

    if (_calculatedResults[layer] == null) {
      _calculatedResults[layer] = <int, int>{};
    }

    if (_activeHitboxes[layer] == null) {
      _activeHitboxes[layer] = [];
    }

    if (_hitboxes[layer] == null) {
      _hitboxes[layer] = {};
    }

    sendResponse(true);
  }

  _layerRemove(String layer) {
    _index.remove(layer);
    _calculatedResults.remove(layer);
    _activeHitboxes.remove(layer);
    _hitboxes.remove(layer);
    sendResponse(true);
  }

  _collisionsUpdate(String layer) {
    _calculatedResults[layer]?.clear();
    final layerHitboxes = _hitboxes[layer] ?? {};
    for (final activeItem in layerHitboxes.entries) {
      final activeHbList = _activeHitboxes[layer] ?? <int>[];
      if (!activeHbList.contains(activeItem.key)) continue;

      final layerOtherHitboxes = _hitboxes[layer] ?? {};
      for (final other in layerOtherHitboxes.entries) {
        var overlap = activeItem.value.intersects(other.value);

        var current = _calculatedResults[layer]?[activeItem.key] ?? 0;
        if (overlap) {
          current++;
        }
        if (_calculatedResults[layer] == null) {
          _calculatedResults[layer] = <int, int>{};
        }
        _calculatedResults[layer]![activeItem.key] = current;
      }
    }
  }

  _hitboxAdd(Message message) {
    final layer = message.layer;
    if (layer == null) throw 'No layer data';

    final newHitbox = _createRect(message);
    if (newHitbox != null) {
      final index = _index[layer] = (_index[layer] ?? 0) + 1;

      var hbList = _hitboxes[layer];
      if (hbList == null) {
        _hitboxes[layer] = <int, Rectangle<double>>{};
        hbList = _hitboxes[layer];
      }
      _hitboxes[layer]![index] = newHitbox;
      if (message.type == CollisionType.active) {
        if (_activeHitboxes[layer] == null) {
          _activeHitboxes[layer] = [];
        }
        _activeHitboxes[layer]!.add(index);
      }
      sendResponse(index);
    }
  }

  _hitboxUpdate(Message message) {
    final layer = message.layer;
    if (layer == null) throw 'No layer data';

    final newHitbox = _createRect(message);
    final id = message.id;
    if (newHitbox != null && id != null) {
      _hitboxes[layer]![id] = newHitbox;
      if (message.type == CollisionType.active &&
          !_activeHitboxes[layer]!.contains(id)) {
        _activeHitboxes[layer]!.add(id);
      }
    }
  }

  _hitboxRemove(Message message) {
    final layer = message.layer;
    if (layer == null) throw 'No layer data';

    final id = message.id;
    if (id != null) {
      _hitboxes[layer]!.remove(id);
      _activeHitboxes[layer]!.remove(id);
    }
  }

  Rectangle<double>? _createRect(Message message) {
    final position = message.position;
    if (position == null) return null;

    final size = message.size;
    if (size == null) return null;

    return Rectangle.fromPoints(Point(position.x, position.y),
        Point(position.x + size.x, position.y + size.y));
  }
}

Future<void> workerIsolateMain(SendPort p) async {
  final server = Worker(p, ReceivePort());
  print('Worker ${server.internalId} started.');
  server.run();
}
