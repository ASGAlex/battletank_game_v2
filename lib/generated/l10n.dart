// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Play!`
  String get start_new_game {
    return Intl.message(
      'Play!',
      name: 'start_new_game',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Tank game`
  String get app_title {
    return Intl.message(
      'Tank game',
      name: 'app_title',
      desc: '',
      args: [],
    );
  }

  /// `Unknown routing error`
  String get p404_title {
    return Intl.message(
      'Unknown routing error',
      name: 'p404_title',
      desc: '',
      args: [],
    );
  }

  /// `Processor speed`
  String get processor_speed {
    return Intl.message(
      'Processor speed',
      name: 'processor_speed',
      desc: '',
      args: [],
    );
  }

  /// `Web browser`
  String get processor_speed_web {
    return Intl.message(
      'Web browser',
      name: 'processor_speed_web',
      desc: '',
      args: [],
    );
  }

  /// `An office PC`
  String get processor_speed_office {
    return Intl.message(
      'An office PC',
      name: 'processor_speed_office',
      desc: '',
      args: [],
    );
  }

  /// `Nice fast processor`
  String get processor_speed_middle {
    return Intl.message(
      'Nice fast processor',
      name: 'processor_speed_middle',
      desc: '',
      args: [],
    );
  }

  /// `High-end CPU for gaming`
  String get processor_speed_powerful {
    return Intl.message(
      'High-end CPU for gaming',
      name: 'processor_speed_powerful',
      desc: '',
      args: [],
    );
  }

  /// `Enable sound`
  String get sounds_enables {
    return Intl.message(
      'Enable sound',
      name: 'sounds_enables',
      desc: '',
      args: [],
    );
  }

  /// `Continue to play`
  String get continue_play {
    return Intl.message(
      'Continue to play',
      name: 'continue_play',
      desc: '',
      args: [],
    );
  }

  /// `Exit the game`
  String get exit {
    return Intl.message(
      'Exit the game',
      name: 'exit',
      desc: '',
      args: [],
    );
  }

  /// `Mission objectives`
  String get mission_objectives {
    return Intl.message(
      'Mission objectives',
      name: 'mission_objectives',
      desc: '',
      args: [],
    );
  }

  /// `This is endless game without any objectives`
  String get mission_objectives_empty {
    return Intl.message(
      'This is endless game without any objectives',
      name: 'mission_objectives_empty',
      desc: '',
      args: [],
    );
  }

  /// `Got it!`
  String get ok {
    return Intl.message(
      'Got it!',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: '',
      args: [],
    );
  }

  /// `Do you really want to leave the game and exit to mission menu?`
  String get leave_game {
    return Intl.message(
      'Do you really want to leave the game and exit to mission menu?',
      name: 'leave_game',
      desc: '',
      args: [],
    );
  }

  /// `How to play?`
  String get controls_description_title {
    return Intl.message(
      'How to play?',
      name: 'controls_description_title',
      desc: '',
      args: [],
    );
  }

  /// `Use WASD for moving \nPress SPACE for fire\nPress E to enter into a vehicle\nPress F to leave a vehicle\nPress ~ to view console\nPress ESC to interrupt a mission`
  String get controls_description {
    return Intl.message(
      'Use WASD for moving \nPress SPACE for fire\nPress E to enter into a vehicle\nPress F to leave a vehicle\nPress ~ to view console\nPress ESC to interrupt a mission',
      name: 'controls_description',
      desc: '',
      args: [],
    );
  }

  /// `VISIBLE`
  String get visible {
    return Intl.message(
      'VISIBLE',
      name: 'visible',
      desc: '',
      args: [],
    );
  }

  /// `HIDDEN`
  String get hidden {
    return Intl.message(
      'HIDDEN',
      name: 'hidden',
      desc: '',
      args: [],
    );
  }

  /// `You must protect {count} primary target(s)`
  String mo_protect_primary_target(int count) {
    return Intl.message(
      'You must protect $count primary target(s)',
      name: 'mo_protect_primary_target',
      desc: '',
      args: [count],
    );
  }

  /// `You must destroy {count} primary target(s)`
  String mo_kill_primary_target(int count) {
    return Intl.message(
      'You must destroy $count primary target(s)',
      name: 'mo_kill_primary_target',
      desc: '',
      args: [count],
    );
  }

  /// `You must protect {count} secondary target(s)`
  String mo_protect_secondary_target(int count) {
    return Intl.message(
      'You must protect $count secondary target(s)',
      name: 'mo_protect_secondary_target',
      desc: '',
      args: [count],
    );
  }

  /// `You must destroy {count} secondary target(s)`
  String mo_kill_secondary_target(int count) {
    return Intl.message(
      'You must destroy $count secondary target(s)',
      name: 'mo_kill_secondary_target',
      desc: '',
      args: [count],
    );
  }

  /// `Targets lost: {count}`
  String mo_target_lost(int count) {
    return Intl.message(
      'Targets lost: $count',
      name: 'mo_target_lost',
      desc: '',
      args: [count],
    );
  }

  /// `Targets killed: {count}`
  String mo_target_killed(int count) {
    return Intl.message(
      'Targets killed: $count',
      name: 'mo_target_killed',
      desc: '',
      args: [count],
    );
  }

  /// `Primary target killed!`
  String get mo_primary_target_just_killed {
    return Intl.message(
      'Primary target killed!',
      name: 'mo_primary_target_just_killed',
      desc: '',
      args: [],
    );
  }

  /// `Secondary target killed!`
  String get mo_secondary_target_just_killed {
    return Intl.message(
      'Secondary target killed!',
      name: 'mo_secondary_target_just_killed',
      desc: '',
      args: [],
    );
  }

  /// `Primary target lost!`
  String get mo_primary_target_just_lost {
    return Intl.message(
      'Primary target lost!',
      name: 'mo_primary_target_just_lost',
      desc: '',
      args: [],
    );
  }

  /// `Secondary target lost!`
  String get mo_secondary_target_just_lost {
    return Intl.message(
      'Secondary target lost!',
      name: 'mo_secondary_target_just_lost',
      desc: '',
      args: [],
    );
  }

  /// `VICTORY!`
  String get victory {
    return Intl.message(
      'VICTORY!',
      name: 'victory',
      desc: '',
      args: [],
    );
  }

  /// `DEFEAT!`
  String get defeat {
    return Intl.message(
      'DEFEAT!',
      name: 'defeat',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
