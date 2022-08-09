import 'dart:async';

class ConsoleMessages {
  final _streamController = StreamController<String>();

  Stream<String> get stream => _streamController.stream;

  final gameMessages = <String>[];

  sendMessage(String msg) {
    gameMessages.add(msg);
    _streamController.add(msg);
  }
}
