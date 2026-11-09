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

  static String m0(language) => "${language} code";

  static String m1(number) => "FIG. ${number}";

  static String m2(number) => "TBL. ${number}";

  static String m3(number) => "Table ${number}";

  static String m4(minutes) => "${minutes} min";

  static String m5(total) => "No module matches both filters · 0 of ${total}";

  static String m6(visible, total) => "Showing ${visible} of ${total}";

  static String m7(ready, total) => "${ready} of ${total} written";

  static String m8(hours) => "~${hours} h";

  static String m9(hours, minutes) => "~${hours} h ${minutes} min";

  static String m10(minutes) => "~${minutes} min";

  static String m11(url) => "Could not open ${url}";

  static String m12(approved, total) => "${approved}/${total} completed";

  static String m13(total) => "--/${total} completed";

  static String m14(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  static String m15(title) => "Complete ${title}";

  static String m16(track) => "Every module, ${track}";

  static String m17(approved, total) => "${approved}/${total}";

  static String m18(number, title) => "${number} ${title}";

  static String m19(signed, total) => "${signed} of ${total}";

  static String m20(index, count) => "Question ${index} of ${count}";

  static String m21(score, total) => "${score} of ${total}";

  static String m22(count) => "${count} questions on the main points of this module";

  static String m23(letter) => "Not this one. The answer is ${letter}.";

  static String m24(date) => "Completed ${date}";

  static String m25(minutes) => "${minutes} min";

  static String m26(number, count) => "MODULE ${number} OF ${count}";

  static String m27(label) => "${label} · Planned";

  static String m28(hash, date) => "Rev ${hash} · ${date}";

  static String m29(reason) => "Not saved: ${reason}. Back up to a file to keep it.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "block_code_label": m0,
    "block_figure_caption": m1,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program output"),
    "block_table_caption": m2,
    "block_table_region": m3,
    "block_unknown": MessageLookupByLibrary.simpleMessage("This part needs a newer version of the app."),
    "card_description": MessageLookupByLibrary.simpleMessage("Description"),
    "card_length": MessageLookupByLibrary.simpleMessage("Length"),
    "card_length_minutes": m4,
    "card_requires": MessageLookupByLibrary.simpleMessage("Requires"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Nothing"),
    "catalog_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "catalog_filter_not_completed": MessageLookupByLibrary.simpleMessage("Not completed"),
    "catalog_filter_planned": MessageLookupByLibrary.simpleMessage("Planned"),
    "catalog_filter_ready": MessageLookupByLibrary.simpleMessage("Ready"),
    "catalog_level_label": MessageLookupByLibrary.simpleMessage("Level:"),
    "catalog_no_match": m5,
    "catalog_no_match_cue": MessageLookupByLibrary.simpleMessage(
      "The two filters select different modules. Widen either one, or clear both to see the whole catalog again.",
    ),
    "catalog_show_all": MessageLookupByLibrary.simpleMessage("Show the whole catalog"),
    "catalog_showing": m6,
    "catalog_status_label": MessageLookupByLibrary.simpleMessage("Status:"),
    "catalog_title": MessageLookupByLibrary.simpleMessage("Catalog"),
    "catalog_written": m7,
    "content_broken_message": MessageLookupByLibrary.simpleMessage(
      "The course content in this app could not be read. Reinstalling the app restores it.",
    ),
    "content_broken_title": MessageLookupByLibrary.simpleMessage("The course cannot be opened"),
    "content_unreadable": MessageLookupByLibrary.simpleMessage(
      "This part of the course could not be read on this device. Restart the app to reload it.",
    ),
    "duration_hours": m8,
    "duration_hours_minutes": m9,
    "duration_minutes": m10,
    "error_link_open_failed": m11,
    "level_completed": m12,
    "level_completed_pending": m13,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("General notes"),
    "level_module_count": m14,
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
    "progress_complete_module": m15,
    "progress_every_module": m16,
    "progress_level_dial": m17,
    "progress_module_link": m18,
    "progress_state_complete": MessageLookupByLibrary.simpleMessage("Complete"),
    "progress_state_not_yet": MessageLookupByLibrary.simpleMessage("Not yet"),
    "progress_tab_count": m19,
    "progress_tabs_label": MessageLookupByLibrary.simpleMessage("Progress by track"),
    "progress_title": MessageLookupByLibrary.simpleMessage("Your progress"),
    "quiz_back_to_questions": MessageLookupByLibrary.simpleMessage("Back to the questions"),
    "quiz_correct": MessageLookupByLibrary.simpleMessage("Correct."),
    "quiz_next": MessageLookupByLibrary.simpleMessage("Next"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quiz_progress": m20,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", correct"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", not correct"),
    "quiz_score_count": m21,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("answered correctly"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("See results"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "quiz_subtitle": m22,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Questions on this module"),
    "quiz_wrong": m23,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Partly written"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Schedule of parts only"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Before you start"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Close"),
    "reader_completed_on": m24,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Module completion"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("Contents"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("End of the course"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Mark this module as complete"),
    "reader_minutes": m25,
    "reader_module_of": m26,
    "reader_next": MessageLookupByLibrary.simpleMessage("Next"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("The For Everyone version of this module is planned."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("What you will be able to do"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("On this page"),
    "reader_pager_planned": m27,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Read it For Engineers"),
    "reader_revision": m28,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Description"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Item"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Schedule of parts"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("See what is written For Everyone"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Start of the course"),
    "record_not_saved": m29,
    "record_not_saved_blocked": MessageLookupByLibrary.simpleMessage("the app could not write its file"),
    "record_not_saved_quota": MessageLookupByLibrary.simpleMessage("this device has no space left"),
    "record_not_saved_too_large": MessageLookupByLibrary.simpleMessage("the record is larger than the app will write"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "track_switch_label": MessageLookupByLibrary.simpleMessage("Track"),
  };
}
