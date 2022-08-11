import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tank_game/generated/l10n.dart';
import 'package:tank_game/ui/route_builder.dart';

import 'services/settings/controller.dart';
import 'ui/intl.dart';

void main(List<String> args) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SettingsController().loadSettings();
      runApp(const MyApp());
    },
    (error, st) =>
        SettingsController().consoleMessages.sendMessage(error.toString()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsController(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
            restorationScopeId: 'app',
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('ru', ''),
            ],
            onGenerateTitle: (BuildContext context) => context.loc().app_title,
            theme: ThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (BuildContext context) =>
                      RouteBuilder.build(routeSettings.name, context));
            },
            onUnknownRoute: (RouteSettings routeSettings) =>
                MaterialPageRoute<void>(
                    settings: routeSettings,
                    builder: (_) => RouteBuilder.notFoundRoute(context)));
      },
    );
  }
}
