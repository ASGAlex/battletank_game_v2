import 'dart:io';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:tank_game/generated/l10n.dart';
import 'package:tank_game/ui/route_builder.dart';

import 'services/settings/controller.dart';
import 'ui/intl.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsController().loadSettings();
  runApp(const MyApp());

  // await runZonedGuarded(
  //   () async {
  //     WidgetsFlutterBinding.ensureInitialized();
  //     SettingsController().loadSettings();
  //     runApp(const MyApp());
  //   },
  //   (error, st) =>
  //       SettingsController().consoleMessages.sendMessage(error.toString()),
  // );
}

class RawKeyEventSim extends RawKeyDownEvent {
  factory RawKeyEventSim(LogicalKeyboardKey simulatedKey) {
    RawKeyEventData? data;
    if (Platform.isWindows) {
      data = const RawKeyEventDataWindows();
    }
    if (data == null) throw 'unsupported platform';
    return RawKeyEventSim._(simulatedKey: simulatedKey, data: data);
  }

  const RawKeyEventSim._({required this.simulatedKey, required super.data});

  final LogicalKeyboardKey simulatedKey;

  @override
  LogicalKeyboardKey get logicalKey => simulatedKey;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final manager = ShortcutManager(
    modal: true,
    shortcuts: const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.keyW): PreviousFocusIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.keyS): NextFocusIntent(),
      SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
  );
  final xinput = SettingsController().xInputGamePadController;

  onXInputKeyPressed() {
    for (final logicalKey in xinput.keysPressed) {
      // final event = RawKeyEventSim(logicalKey);
      // ignore: invalid_use_of_protected_member
      // manager.handleKeypress(context, event);
    }
  }

  @override
  void dispose() {
    xinput.dispose();
    // SoundLibrary.dispose();
    super.dispose();
  }

  @override
  void initState() {
    Flame.device.setLandscape();
    Flame.device.fullScreen();
    // SoundLibrary.loadSounds();
    // xinput.addListener(onXInputKeyPressed);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts.manager(
      manager: manager,
      child: AnimatedBuilder(
        animation: SettingsController(),
        builder: (BuildContext context, Widget? child) {
          var nesTheme = flutterNesTheme(brightness: Brightness.light);
          nesTheme = nesTheme.copyWith(
              scrollbarTheme: ScrollbarTheme.of(context).copyWith(
            radius: Radius.zero,
            thickness: const MaterialStatePropertyAll<double>(20),
            thumbColor: const MaterialStatePropertyAll<Color>(Colors.white54),
            trackVisibility: const MaterialStatePropertyAll<bool>(false),
            thumbVisibility: const MaterialStatePropertyAll<bool>(true),
          ));
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
              onGenerateTitle: (BuildContext context) =>
                  context.loc().app_title,
              theme: nesTheme,
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
      ),
    );
  }
}
