import 'package:flutter/material.dart';
import 'package:tank_game/world/core/scenario/scenario_description.dart';

import 'game/screen.dart';
import 'intl.dart';
import 'menu/main_menu.dart';
import 'menu/mission_menu.dart';
import 'menu/setings_menu.dart';

typedef RouteItem = Widget Function(BuildContext context);

class RouteBuilder {
  static final _routeMap = <String, RouteItem>{
    '/': (ctx) => const MainMenu(),
    // '/': (ctx) => _gameRoute(),
    '/main': (ctx) => const MainMenu(),
    '/missions': (ctx) => const MissionMenu(),
    '/settings': (ctx) => const SettingsMenu(),
    '/game': (ctx) => _gameRoute(ctx),
  };

  static Widget build(String? routeName, BuildContext context) {
    final routeFunc = _routeMap[routeName];
    if (routeFunc == null) {
      return notFoundRoute(context);
    }

    return routeFunc(context);
  }

  static Widget notFoundRoute(BuildContext context) => Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.purple,
            title: Text(context.loc().p404_title)),
        body: Container(),
      );

  static Widget _gameRoute([BuildContext? context]) {
    if (context != null) {
      final mission = ModalRoute.of(context)?.settings.arguments;
      if (mission != null && mission is Scenario) {
        return GameScreen(
          key: UniqueKey(),
          mission: mission,
        );
      }
    }
    return GameScreen(
      key: UniqueKey(),
      mission: Scenario(
          name: 'mission',
          description: 'description',
          mapFile: 'performance_test.tmx'),
    );
  }

  static gotoMainMenu(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  static gotoGameProcess(BuildContext context, Scenario mission) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/game', (route) => false, arguments: mission);
  }

  static gotoMissions(BuildContext context, [bool restorable = true]) {
    if (restorable) {
      Navigator.of(context).restorablePushNamed('/missions');
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/missions', (route) => false);
    }
  }

  static gotoSettings(BuildContext context) {
    Navigator.of(context).restorablePushNamed('/settings');
  }
}
