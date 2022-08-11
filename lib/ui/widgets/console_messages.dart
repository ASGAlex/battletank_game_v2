import 'dart:async';

import 'package:flutter/material.dart';

class ConsoleMessagesController {
  final _streamController = StreamController<String>.broadcast();

  Stream<String> get stream => _streamController.stream;

  final gameMessages = <String>[];

  sendMessage(String msg) {
    gameMessages.add(msg);
    _streamController.add(msg);
  }
}

class ConsoleMessages extends StatelessWidget {
  const ConsoleMessages({Key? key, required this.controller}) : super(key: key);

  final ConsoleMessagesController controller;

  @override
  Widget build(BuildContext context) {
    final msgScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        msgScrollController
            .jumpTo(msgScrollController.position.maxScrollExtent);
      } catch (e) {}
    });
    return Container(
      color: Colors.black,
      margin: const EdgeInsets.fromLTRB(32, 16, 16, 16),
      child: ListView.builder(
        itemExtent: 24,
        controller: msgScrollController,
        itemCount: controller.gameMessages.length,
        reverse: false,
        itemBuilder: (BuildContext context, int index) {
          return Row(
            verticalDirection: VerticalDirection.up,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: const TextStyle(
                    decoration: null,
                    color: Colors.white,
                    fontFamily: 'MonospaceRU',
                    fontSize: 12),
                child: Text(
                  controller.gameMessages[index],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
