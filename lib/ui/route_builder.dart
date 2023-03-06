import 'package:flutter/material.dart';
import 'package:tank_game/mission/repository.dart';

import 'game/screen.dart';
import 'intl.dart';
import 'menu/main_menu.dart';
import 'menu/mission_menu.dart';
import 'menu/settings/setings_view.dart';

typedef RouteItem = Widget Function(BuildContext context);

class RouteBuilder {
  static final _routeMap = <String, RouteItem>{
    // '/': (ctx) => const MainMenu(),
    '/': (ctx) => _gameRoute(),
    '/main': (ctx) => const MainMenu(),
    '/missions': (ctx) => const MissionMenu(),
    '/settings': (ctx) => const SettingsView(),
    '/game': (ctx) => _gameRoute(),
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

  static Widget _gameRoute() {
    return GameScreen(
      mission: MissionDescription(
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

  static gotoGameProcess(BuildContext context, MissionDescription mission) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/game', (route) => false, arguments: mission);
  }

  static gotoMissions(BuildContext context) {
    Navigator.of(context).restorablePushNamed('/missions');
  }

  static gotoSettings(BuildContext context) {
    Navigator.of(context).restorablePushNamed('/settings');
  }
}
