import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flame/components.dart';
import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tank_game/controls/input_events_handler.dart';
import 'package:tank_game/world/core/scenario/scripts/event.dart';

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    Key? key,
    required this.texts,
    this.provider,
    this.scenarioEventProvider,
    this.onFinish,
    this.textBoxMaxHeight = 500,
    this.keyboardKeysToNext = const [],
    this.talkAlignment = Alignment.topCenter,
    this.style,
    this.speed = const Duration(milliseconds: 10),
    this.isModal = false,
    this.triggerComponent,
  }) : super(key: key);

  final Component? triggerComponent;
  final List<String> texts;
  final VoidCallback? onFinish;
  final double textBoxMaxHeight;
  final List<LogicalKeyboardKey> keyboardKeysToNext;
  final Alignment talkAlignment;
  final TextStyle? style;
  final bool isModal;
  final MessageStreamProvider<List<PlayerAction>>? provider;
  final MessageStreamProvider<ScenarioEvent>? scenarioEventProvider;

  /// in milliseconds
  final Duration speed;

  @override
  MessageWidgetState createState() => MessageWidgetState();
}

class MessageWidgetState extends State<MessageWidget>
    with MessageListenerMixin<List<PlayerAction>> {
  late String currentText;
  int currentIndex = 0;
  bool finishedCurrentSay = false;

  @override
  void initState() {
    currentText = widget.texts[currentIndex];
    if (widget.provider != null) {
      listenProvider(widget.provider!);
    }
    super.initState();
  }

  @override
  void dispose() {
    disposeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget content = Container(
    //   color: Colors.transparent,
    //   padding: const EdgeInsets.all(10),
    //   child: Stack(
    //     alignment: widget.talkAlignment,
    //     children: [
    //       const Align(
    //         alignment: Alignment.bottomLeft,
    //         child: SizedBox.shrink(),
    //       ),
    //     ],
    //   ),
    // );
    return Material(
        type: MaterialType.transparency,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox.shrink(),
                  Container(
                    width: double.maxFinite,
                    margin: const EdgeInsets.fromLTRB(80, 4, 80, 10),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxHeight: widget.textBoxMaxHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      // borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    child: AnimatedTextKit(
                      key: ValueKey<String>(currentText),
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      onFinished: widget.onFinish,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          currentText,
                          speed: widget.speed,
                          textStyle: const TextStyle(
                            fontFamily: 'MonospaceRu',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          cursor: '_',
                        )
                      ],
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ));
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    if (message.contains(PlayerAction.triggerE)) {
      if (currentIndex < widget.texts.length - 1) {
        setState(() {
          currentIndex++;
          currentText = widget.texts[currentIndex];
        });
      } else {
        if (widget.triggerComponent != null &&
            widget.scenarioEventProvider != null) {
          widget.scenarioEventProvider!.sendMessage(MessageListFinishedEvent(
            emitter: widget.triggerComponent!,
            data: currentIndex,
          ));
        }
      }
    }
  }
}

class MessageListFinishedEvent extends ScenarioEvent {
  const MessageListFinishedEvent({required super.emitter, required super.data})
      : super(name: 'MessageListFinishedEvent');
}
