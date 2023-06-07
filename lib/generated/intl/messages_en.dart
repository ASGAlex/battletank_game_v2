// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(count) => "You must destroy ${count} primary target(s)";

  static String m1(count) => "You must destroy ${count} secondary target(s)";

  static String m2(count) => "You must protect ${count} primary target(s)";

  static String m3(count) => "You must protect ${count} secondary target(s)";

  static String m4(count) => "Targets killed: ${count}";

  static String m5(count) => "Targets lost: ${count}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "app_title": MessageLookupByLibrary.simpleMessage("Tank game"),
        "continue_play":
            MessageLookupByLibrary.simpleMessage("Continue to play"),
        "defeat": MessageLookupByLibrary.simpleMessage("DEFEAT!"),
        "exit": MessageLookupByLibrary.simpleMessage("Exit the game"),
        "graphics_low": MessageLookupByLibrary.simpleMessage("Low"),
        "graphics_quality":
            MessageLookupByLibrary.simpleMessage("Graphics quality"),
        "graphics_treeShadow":
            MessageLookupByLibrary.simpleMessage("Shadows for trees and tanks"),
        "graphics_walls3DShadows_medium":
            MessageLookupByLibrary.simpleMessage("Well-detailed 3D"),
        "graphics_walls3D_low":
            MessageLookupByLibrary.simpleMessage("Pseudo-3D walls"),
        "graphics_walls3dShadows_high":
            MessageLookupByLibrary.simpleMessage("Highest 3D detalisation"),
        "graphics_walls3dShadows_low": MessageLookupByLibrary.simpleMessage(
            "Pseudo-3D walls with shadows"),
        "hidden": MessageLookupByLibrary.simpleMessage("HIDDEN"),
        "mission_objectives":
            MessageLookupByLibrary.simpleMessage("Mission objectives"),
        "mission_objectives_empty": MessageLookupByLibrary.simpleMessage(
            "This is endless game without any objectives"),
        "mo_kill_primary_target": m0,
        "mo_kill_secondary_target": m1,
        "mo_primary_target_just_killed":
            MessageLookupByLibrary.simpleMessage("Primary target killed!"),
        "mo_primary_target_just_lost":
            MessageLookupByLibrary.simpleMessage("Primary target lost!"),
        "mo_protect_primary_target": m2,
        "mo_protect_secondary_target": m3,
        "mo_secondary_target_just_killed":
            MessageLookupByLibrary.simpleMessage("Secondary target killed!"),
        "mo_secondary_target_just_lost":
            MessageLookupByLibrary.simpleMessage("Secondary target lost!"),
        "mo_target_killed": m4,
        "mo_target_lost": m5,
        "ok": MessageLookupByLibrary.simpleMessage("Got it!"),
        "p404_title":
            MessageLookupByLibrary.simpleMessage("Unknown routing error"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "start_new_game": MessageLookupByLibrary.simpleMessage("Play!"),
        "victory": MessageLookupByLibrary.simpleMessage("VICTORY!"),
        "visible": MessageLookupByLibrary.simpleMessage("VISIBLE")
      };
}
