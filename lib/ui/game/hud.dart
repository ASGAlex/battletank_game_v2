import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/intl.dart';

class HUDWidget extends StatelessWidget {
  const HUDWidget({super.key, required this.game});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              width: 200,
              height: 30,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder(
                        stream: game.hudHideInTreesProvider.messagingStream,
                        builder: (context, snapshot) {
                          final hidden = snapshot.data ?? false;
                          var text = context.loc().visible;
                          var bgColor = Colors.white.withOpacity(0.5);
                          var fontColor = Colors.black;
                          if (hidden) {
                            text = context.loc().hidden;
                            bgColor = Colors.green;
                            fontColor = Colors.white;
                          }
                          return Container(
                            color: bgColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                text,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: fontColor,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'MonospaceRU',
                                    backgroundColor: bgColor.withOpacity(0)),
                              ),
                            ),
                          );
                        })
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
