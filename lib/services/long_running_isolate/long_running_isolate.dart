import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

abstract class LongRunningIsolateClient {
  late SendPort _sendPort;
  StreamQueue<dynamic>? _events;

  Isolate? _init;

  bool get init => _init != null;

  bool _debug = false;

  bool get debug => _debug;

  run(
      [Map<String, Duration> layers = const {
        'default': Duration(milliseconds: 500)
      }]);

  @protected
  runMain(Future<void> Function(SendPort message) isolateMain,
      [bool dbg = false]) async {
    final p = ReceivePort();
    _debug = dbg;
    if (debug) {
      isolateMain(p.sendPort);
    } else {
      _init = await Isolate.spawn<SendPort>(isolateMain, p.sendPort);
    }
    _events = StreamQueue<dynamic>(p);
    _sendPort = await _events?.next;
  }

  sendMessage(dynamic message) {
    if (init || debug) {
      _sendPort.send(message);
    }
  }

  Future<dynamic> nextEvent() async => await _events?.next;

  stop() async {
    if (init || debug) {
      _sendPort.send(null);

      await _events?.cancel();
      _init?.kill(priority: Isolate.immediate);
      _init = null;
      _debug = false;
    }
  }
}

abstract class LongRunningIsolateServer {
  LongRunningIsolateServer(this._sendPort, this._receivePort)
      : _id = DateTime.now().microsecondsSinceEpoch {
    _sendPort.send(_receivePort.sendPort);
  }

  final int _id;

  int get internalId => _id;

  final ReceivePort _receivePort;
  final SendPort _sendPort;

  run() async {
    await for (final message in _receivePort) {
      if (message == null) {
        break;
      }

      // print('Worker $internalId received an message');
      processMessage(message);
    }

    print('Spawned isolate finished.');
    Isolate.exit();
  }

  processMessage(dynamic message);

  sendResponse(dynamic response) => _sendPort.send(response);
}
//
// Future<void> _isolateMain(SendPort p) async {
//   print('Spawned isolate started.');
//   final server = LongRunningIsolateServer(p, ReceivePort());
//   server.run();
// }
