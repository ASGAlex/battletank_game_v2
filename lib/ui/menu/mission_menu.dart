import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/services/settings/controller.dart';
import 'package:tank_game/ui/intl.dart';
import 'package:tank_game/ui/route_builder.dart';

class MissionMenu extends StatelessWidget {
  const MissionMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController();
    return NesContainer(
        backgroundColor: Colors.blueGrey,
        child: ListView.builder(
            itemCount: settings.scenarios.length + 2,
            itemBuilder: (BuildContext context, int index) {
              if (index == settings.scenarios.length) {
                return const Divider();
              } else if (index == settings.scenarios.length + 1) {
                return NesButton(
                  type: NesButtonType.primary,
                  child: Text(context.loc().back),
                  onPressed: () {
                    RouteBuilder.gotoMainMenu(context);
                  },
                );
              } else {
                final mission = settings.scenarios[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: NesButton(
                    onPressed: () {
                      NesConfirmDialog.show(
                              context: context,
                              message: mission.description,
                              cancelLabel: context.loc().back,
                              confirmLabel: context.loc().ok)
                          .then((run) {
                        if (run == true) {
                          RouteBuilder.gotoGameProcess(context, mission);
                        }
                      });
                    },
                    type: NesButtonType.success,
                    child: Text(
                      mission.name,
                    ),
                  ),
                );
              }
            }));
  }
}
