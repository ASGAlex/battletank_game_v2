import 'package:flutter/material.dart';

import 'game/screen.dart';
import 'intl.dart';
import 'menu/menu.dart';
import 'menu/settings/setings_view.dart';

typedef RouteItem = Widget Function(BuildContext context);

class RouteBuilder {
  static final _routeMap = <String, RouteItem>{
    '/': (ctx) => const MainMenu(),
    '/main': (ctx) => const MainMenu(),
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
    return const GameScreen();
  }

  static gotoGameProcess(BuildContext context) {
    Navigator.of(context).restorablePushNamed('/game');
  }

  static gotoSettings(BuildContext context) {
    Navigator.of(context).restorablePushNamed('/settings');
  }
}
