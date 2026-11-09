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

  static String m0(number) => "FIG. ${number}";

  static String m1(number) => "TBL. ${number}";

  static String m2(minutes) => "${minutes} min";

  static String m3(total) => "No module matches both filters · 0 of ${total}";

  static String m4(visible, total) => "Showing ${visible} of ${total}";

  static String m5(ready, total) => "${ready} of ${total} written";

  static String m6(hours) => "~${hours} h";

  static String m7(hours, minutes) => "~${hours} h ${minutes} min";

  static String m8(minutes) => "~${minutes} min";

  static String m9(url) => "Could not open ${url}";

  static String m10(approved, total) => "${approved}/${total} completed";

  static String m11(total) => "--/${total} completed";

  static String m12(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "block_figure_caption": m0,
    "block_table_caption": m1,
    "card_description": MessageLookupByLibrary.simpleMessage("Description"),
    "card_length": MessageLookupByLibrary.simpleMessage("Length"),
    "card_length_minutes": m2,
    "card_requires": MessageLookupByLibrary.simpleMessage("Requires"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Nothing"),
    "catalog_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "catalog_filter_not_completed": MessageLookupByLibrary.simpleMessage("Not completed"),
    "catalog_filter_planned": MessageLookupByLibrary.simpleMessage("Planned"),
    "catalog_filter_ready": MessageLookupByLibrary.simpleMessage("Ready"),
    "catalog_level_label": MessageLookupByLibrary.simpleMessage("Level:"),
    "catalog_no_match": m3,
    "catalog_no_match_cue": MessageLookupByLibrary.simpleMessage(
      "The two filters select different modules. Widen either one, or clear both to see the whole catalog again.",
    ),
    "catalog_show_all": MessageLookupByLibrary.simpleMessage("Show the whole catalog"),
    "catalog_showing": m4,
    "catalog_status_label": MessageLookupByLibrary.simpleMessage("Status:"),
    "catalog_title": MessageLookupByLibrary.simpleMessage("Catalog"),
    "catalog_written": m5,
    "content_broken_message": MessageLookupByLibrary.simpleMessage(
      "The course content in this app could not be read. Reinstalling the app restores it.",
    ),
    "content_broken_title": MessageLookupByLibrary.simpleMessage("The course cannot be opened"),
    "content_unreadable": MessageLookupByLibrary.simpleMessage(
      "This part of the course could not be read on this device. Restart the app to reload it.",
    ),
    "duration_hours": m6,
    "duration_hours_minutes": m7,
    "duration_minutes": m8,
    "error_link_open_failed": m9,
    "level_completed": m10,
    "level_completed_pending": m11,
    "level_module_count": m12,
    "loading": MessageLookupByLibrary.simpleMessage("Loading"),
    "module_planned": MessageLookupByLibrary.simpleMessage("Planned"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("Catalog"),
    "nav_progress": MessageLookupByLibrary.simpleMessage("Progress"),
    "nav_settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "not_found_message": MessageLookupByLibrary.simpleMessage(
      "This address is not a module in the curriculum. The catalog lists every one that is.",
    ),
    "not_found_title": MessageLookupByLibrary.simpleMessage("No such module"),
    "open_on_the_web": MessageLookupByLibrary.simpleMessage("Open on the web"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "track_switch_label": MessageLookupByLibrary.simpleMessage("Track"),
  };
}
