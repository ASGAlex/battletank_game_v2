import 'package:flutter/material.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/route_builder.dart';
import 'package:tank_game/ui/widgets/button.dart';

class MissionMenu extends StatelessWidget {
  const MissionMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController();
    return Container(
        padding: const EdgeInsets.only(top: 24, right: 100, left: 100),
        child: ListView.builder(
            itemCount: settings.missions.length,
            itemBuilder: (BuildContext context, int index) {
              final mission = settings.missions[index];
              return MenuButton(
                  onPressed: () {
                    RouteBuilder.gotoGameProcess(context, mission);
                  },
                  text: mission.name);
            }));
  }
}
