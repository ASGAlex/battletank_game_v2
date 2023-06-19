// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static String m0(count) => "Необходимо уничтожить основных целей: ${count}";

  static String m1(count) =>
      "Желательно уничтожить дополнительные цели: ${count}";

  static String m2(count) => "Необходимо защитить основных целей: ${count}";

  static String m3(count) =>
      "Желательно защитить дополнительные цели: ${count}";

  static String m4(count) => "Целей уничтожено: ${count}";

  static String m5(count) => "Целей потеряно: ${count}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "app_title": MessageLookupByLibrary.simpleMessage("Танки"),
        "back": MessageLookupByLibrary.simpleMessage("Назад"),
        "continue_play":
            MessageLookupByLibrary.simpleMessage("Продолжить игру"),
        "controls_description": MessageLookupByLibrary.simpleMessage(
            "WASD для передвижения \nSPACE - открыть огонь\nE - войти в транспорт\nF - покинуть транспорт\nЧтобы показать консоль - нажми ~\nESC - прервать миссию"),
        "controls_description_title":
            MessageLookupByLibrary.simpleMessage("Как играть"),
        "defeat": MessageLookupByLibrary.simpleMessage("Поражение!"),
        "exit": MessageLookupByLibrary.simpleMessage("Выйти из игры"),
        "hidden": MessageLookupByLibrary.simpleMessage("СКРЫТЫЙ"),
        "leave_game": MessageLookupByLibrary.simpleMessage(
            "Точно хочешь остаовить игру и вернуться в меню выбора миссий?"),
        "mission_objectives":
            MessageLookupByLibrary.simpleMessage("Задачи миссии"),
        "mission_objectives_empty": MessageLookupByLibrary.simpleMessage(
            "Это бесконечная игра без каких-либо заданий"),
        "mo_kill_primary_target": m0,
        "mo_kill_secondary_target": m1,
        "mo_primary_target_just_killed":
            MessageLookupByLibrary.simpleMessage("Основная цель уничтожена!"),
        "mo_primary_target_just_lost":
            MessageLookupByLibrary.simpleMessage("Основная цель потеряна!"),
        "mo_protect_primary_target": m2,
        "mo_protect_secondary_target": m3,
        "mo_secondary_target_just_killed": MessageLookupByLibrary.simpleMessage(
            "Дополнительная цель уничтожена!"),
        "mo_secondary_target_just_lost": MessageLookupByLibrary.simpleMessage(
            "Дополнительная цель потеряна!"),
        "mo_target_killed": m4,
        "mo_target_lost": m5,
        "ok": MessageLookupByLibrary.simpleMessage("Так точно!"),
        "p404_title":
            MessageLookupByLibrary.simpleMessage("Unknown routing error"),
        "processor_speed":
            MessageLookupByLibrary.simpleMessage("Скорость процессора"),
        "processor_speed_middle":
            MessageLookupByLibrary.simpleMessage("Мощный, но не топовый"),
        "processor_speed_office":
            MessageLookupByLibrary.simpleMessage("Офисный компьютер"),
        "processor_speed_powerful": MessageLookupByLibrary.simpleMessage(
            "Крутой процессор для гейминга"),
        "processor_speed_web":
            MessageLookupByLibrary.simpleMessage("Web-браузер"),
        "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
        "start_new_game": MessageLookupByLibrary.simpleMessage("Играть!"),
        "victory": MessageLookupByLibrary.simpleMessage("Победа!"),
        "visible": MessageLookupByLibrary.simpleMessage("ВИДИМЫЙ")
      };
}
