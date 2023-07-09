import 'dart:async';

import 'package:flame_message_stream/flame_message_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tank_game/controls/input_events_handler.dart';

class TalkDialog extends StatefulWidget {
  const TalkDialog({
    Key? key,
    required this.says,
    this.provider,
    this.onFinish,
    this.onChangeTalk,
    this.textBoxMinHeight = 100,
    this.keyboardKeysToNext = const [],
    this.nextOnTap = false,
    this.nextOnAnyKey = false,
    this.padding,
    this.onClose,
    this.dismissible = false,
    this.talkAlignment = Alignment.bottomCenter,
    this.style,
    this.speed = 50,
    this.isModal = false,
  }) : super(key: key);

  static show(
    BuildContext context,
    List<Say> sayList, {
    VoidCallback? onFinish,
    VoidCallback? onClose,
    ValueChanged<int>? onChangeTalk,
    Color? backgroundColor,
    double boxTextHeight = 100,
    List<LogicalKeyboardKey> logicalKeyboardKeysToNext = const [],
    bool nextOnTap = false,
    bool nextOnAnyKey = false,
    EdgeInsetsGeometry? padding,
    bool dismissible = false,
    Alignment talkAlignment = Alignment.bottomCenter,
    TextStyle? style,
    int speed = 50,
  }) {
    showDialog(
      barrierDismissible: dismissible,
      barrierColor: backgroundColor,
      context: context,
      builder: (BuildContext context) {
        return TalkDialog(
          says: sayList,
          onFinish: onFinish,
          onClose: onClose,
          onChangeTalk: onChangeTalk,
          textBoxMinHeight: boxTextHeight,
          keyboardKeysToNext: logicalKeyboardKeysToNext,
          nextOnTap: nextOnTap,
          nextOnAnyKey: nextOnAnyKey,
          padding: padding,
          dismissible: dismissible,
          talkAlignment: talkAlignment,
          style: style,
          speed: speed,
          isModal: true,
        );
      },
    );
  }

  final List<Say> says;
  final VoidCallback? onFinish;
  final VoidCallback? onClose;
  final ValueChanged<int>? onChangeTalk;
  final double? textBoxMinHeight;
  final List<LogicalKeyboardKey> keyboardKeysToNext;
  final bool nextOnTap;
  final bool nextOnAnyKey;
  final EdgeInsetsGeometry? padding;
  final bool dismissible;
  final Alignment talkAlignment;
  final TextStyle? style;
  final bool isModal;
  final MessageStreamProvider<List<PlayerAction>>? provider;

  /// in milliseconds
  final int speed;

  @override
  TalkDialogState createState() => TalkDialogState();
}

class TalkDialogState extends State<TalkDialog>
    with MessageListenerMixin<List<PlayerAction>> {
  final FocusNode _focusNode = FocusNode();
  late Say currentSay;
  int currentIndexTalk = 0;
  bool finishedCurrentSay = false;

  final GlobalKey<TypeWriterState> _writerKey = GlobalKey();

  @override
  void initState() {
    currentSay = widget.says[currentIndexTalk];
    Future.delayed(Duration.zero, () {
      _focusNode.requestFocus();
    });
    if (widget.provider != null) {
      listenProvider(widget.provider!);
    }
    super.initState();
  }

  @override
  void dispose() {
    widget.onClose?.call();
    _focusNode.dispose();
    disposeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: Colors.transparent,
      padding: widget.padding ?? const EdgeInsets.all(10),
      child: Stack(
        alignment: widget.talkAlignment,
        children: [
          Align(
            alignment: _getAlign(currentSay.personSayDirection),
            child: currentSay.background ?? const SizedBox.shrink(),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              ..._buildPerson(PersonSayDirection.left),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    currentSay.header ?? const SizedBox.shrink(),
                    Container(
                      width: double.maxFinite,
                      padding: currentSay.padding ?? const EdgeInsets.all(10),
                      margin: currentSay.margin,
                      constraints: widget.textBoxMinHeight != null
                          ? BoxConstraints(
                              minHeight: widget.textBoxMinHeight!,
                            )
                          : null,
                      decoration: currentSay.boxDecoration ??
                          BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            // borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                      child: TypeWriter(
                        key: _writerKey,
                        text: currentSay.text,
                        speed: widget.speed,
                        style: widget.style ??
                            const TextStyle(
                              fontFamily: 'MonospaceRu',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                        onFinish: () {
                          finishedCurrentSay = true;
                        },
                      ),
                    ),
                    currentSay.bottom ?? const SizedBox.shrink(),
                  ],
                ),
              ),
              ..._buildPerson(PersonSayDirection.right),
            ],
          ),
        ],
      ),
    );
    if (widget.nextOnTap) {
      content = GestureDetector(
        onTap: _nextOrFinish,
        child: content,
      );
    }
    if (widget.keyboardKeysToNext.isNotEmpty || widget.nextOnAnyKey) {
      content = RawKeyboardListener(
          focusNode: _focusNode,
          onKey: (raw) {
            if (widget.keyboardKeysToNext.isEmpty &&
                raw is RawKeyDownEvent &&
                widget.nextOnAnyKey) {
              // Prevent volume buttons from triggering the next dialog
              if (raw.logicalKey != LogicalKeyboardKey.audioVolumeUp &&
                  raw.logicalKey != LogicalKeyboardKey.audioVolumeDown) {
                _nextOrFinish();
              }
            } else if (widget.keyboardKeysToNext.contains(raw.logicalKey) &&
                raw is RawKeyDownEvent) {
              _nextOrFinish();
            }
          },
          child: content);
    }
    return Material(
      type: MaterialType.transparency,
      child: content,
    );
  }

  void _finishCurrentSay() {
    _writerKey.currentState?.finishTyping();
    finishedCurrentSay = true;
  }

  void _nextSay() {
    currentIndexTalk++;
    if (currentIndexTalk < widget.says.length) {
      setState(() {
        finishedCurrentSay = false;
        currentSay = widget.says[currentIndexTalk];
      });
      _writerKey.currentState?.start(text: currentSay.text);
      widget.onChangeTalk?.call(currentIndexTalk);
    } else {
      widget.onFinish?.call();
      if (widget.isModal) {
        Navigator.pop(context);
      }
    }
  }

  void _nextOrFinish() {
    if (finishedCurrentSay) {
      _nextSay();
    } else {
      _finishCurrentSay();
    }
  }

  List<Widget> _buildPerson(PersonSayDirection direction) {
    if (currentSay.personSayDirection == direction) {
      return [
        if (direction == PersonSayDirection.right && currentSay.person != null)
          SizedBox(
            width: (widget.padding ?? const EdgeInsets.all(10)).horizontal / 2,
          ),
        SizedBox(
          key: UniqueKey(),
          child: currentSay.person,
        ),
        if (direction == PersonSayDirection.left && currentSay.person != null)
          SizedBox(
            width: (widget.padding ?? const EdgeInsets.all(10)).horizontal / 2,
          ),
      ];
    } else {
      return [];
    }
  }

  Alignment _getAlign(PersonSayDirection personDirection) {
    return personDirection == PersonSayDirection.left
        ? Alignment.bottomLeft
        : Alignment.bottomRight;
  }

  @override
  void onStreamMessage(List<PlayerAction> message) {
    if (message.contains(PlayerAction.triggerE)) {
      _nextOrFinish();
    }
  }
}

enum PersonSayDirection { left, right }

class Say {
  /// List of TextSpans to be shown in a TalkDialog.
  /// Example:
  /// ```dart
  /// [
  ///   TextSpan(text: 'New'),
  ///   TextSpan(text: ' item ', style: TextStyle(color: Colors.red)),
  ///   TextSpan(text: 'unlocked!'),
  /// ]
  /// ```
  final List<TextSpan> text;
  final Widget? person;
  final PersonSayDirection personSayDirection;
  final BoxDecoration? boxDecoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? background;
  final Widget? header;
  final Widget? bottom;

  /// How long each character takes to be shown, in milliseconds.
  /// Defaults to 50.
  final int? speed;

  /// Create a text animation to be shown inside `TalkDialog.show`
  Say({
    required this.text,
    this.personSayDirection = PersonSayDirection.left,
    this.boxDecoration,
    this.padding,
    this.margin,
    this.person,
    this.background,
    this.header,
    this.bottom,
    this.speed,
  });
}

class TypeWriter extends StatefulWidget {
  final TextStyle? style;
  final List<TextSpan> text;
  final VoidCallback? onFinish;
  final int speed;
  final bool autoStart;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any. If there is no ambient
  /// [Directionality], then this must not be null.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  const TypeWriter({
    Key? key,
    this.style,
    required this.text,
    this.speed = 50,
    this.autoStart = true,
    this.onFinish,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
  }) : super(key: key);

  @override
  State<TypeWriter> createState() => TypeWriterState();
}

class TypeWriterState extends State<TypeWriter> {
  late StreamController<List<TextSpan>> _textSpanController;
  late List<TextSpan> textSpanList;
  bool _finished = false;

  @override
  void initState() {
    textSpanList = widget.text;
    _textSpanController = StreamController<List<TextSpan>>.broadcast();
    if (widget.autoStart) {
      Future.delayed(Duration.zero, start);
    }
    super.initState();
  }

  @override
  void dispose() {
    _textSpanController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TextSpan>>(
      stream: _textSpanController.stream,
      builder: (context, snapshot) {
        return RichText(
          locale: widget.locale,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          softWrap: widget.softWrap,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          textScaleFactor: widget.textScaleFactor,
          textWidthBasis: widget.textWidthBasis,
          text: TextSpan(
            children: snapshot.data,
            style: widget.style,
          ),
        );
      },
    );
  }

  void start({List<TextSpan>? text}) async {
    _finished = false;
    if (text != null) {
      textSpanList = text;
    }
    // Clean the stream to prevent textStyle from changing before the text
    _textSpanController.add([const TextSpan()]);

    for (var span in textSpanList) {
      if (_textSpanController.isClosed) return;
      for (int i = 0; i < (span.text?.length ?? 0); i++) {
        await Future.delayed(Duration(milliseconds: widget.speed));
        if (_textSpanController.isClosed || _finished) return;
        _textSpanController.add(
          [
            ...textSpanList.sublist(0, textSpanList.indexOf(span)),
            TextSpan(
              text: span.text?.substring(0, i + 1),
              style: span.style,
            ),
          ],
        );
      }
    }
    _finished = true;
    widget.onFinish?.call();
  }

  void finishTyping() {
    _finished = true;
    _textSpanController.add([...textSpanList]);
    widget.onFinish?.call();
  }
}
