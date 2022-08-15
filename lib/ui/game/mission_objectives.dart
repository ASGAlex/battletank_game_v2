import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tank_game/game.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/widgets/button.dart';
import 'package:tank_game/world/environment/target.dart';

import '../widgets/button.dart';

class MissionObjectives extends StatelessWidget {
  const MissionObjectives({Key? key, required this.game}) : super(key: key);
  final MyGame game;

  @override
  Widget build(BuildContext context) {
    final objectives = Target.checkMissionObjectives(context.loc());
    final widgets = <Widget>[];
    for (final obj in objectives) {
      widgets.add(Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 50, bottom: 8),
            child: Text(obj),
          )
        ],
      ));
    }
    if (widgets.isEmpty) {
      widgets.add(Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 50, bottom: 8),
            child: Text(context.loc().mission_objectives_empty),
          )
        ],
      ));
    }
    widgets.add(SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MenuButton(
            onPressed: () {
              game.overlays.remove('mission_objectives');
            },
            text: context.loc().ok,
          ),
        ],
      ),
    ));
    return DefaultTextStyle(
      style: const TextStyle(decoration: null, color: Colors.white),
      child: Container(
        alignment: Alignment.center,
        color: Colors.black26.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 100),
            child: ListView(children: widgets),
          ),
        ),
      ),
    );
  }
}
