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

  static String m8(day) => "Backed up ${day}";

  static String m9(seconds) =>
      "${Intl.plural(seconds, one: 'Reset. You can undo it for 1 second.', other: 'Reset. You can undo it for ${seconds} seconds.')}";

  static String m10(count) => "${Intl.plural(count, one: '1 module state', other: '${count} module states')}";

  static String m11(hours) => "~${hours} h";

  static String m12(hours, minutes) => "~${hours} h ${minutes} min";

  static String m13(minutes) => "~${minutes} min";

  static String m14(url) => "Could not open ${url}";

  static String m15(approved, total) => "${approved}/${total} completed";

  static String m16(total) => "--/${total} completed";

  static String m17(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  static String m18(title) => "Complete ${title}";

  static String m19(track) => "Every module, ${track}";

  static String m20(approved, total) => "${approved}/${total}";

  static String m21(number, title) => "${number} ${title}";

  static String m22(signed, total) => "${signed} of ${total}";

  static String m23(index, count) => "Question ${index} of ${count}";

  static String m24(score, total) => "${score} of ${total}";

  static String m25(count) => "${count} questions on the main points of this module";

  static String m26(letter) => "Not this one. The answer is ${letter}.";

  static String m27(date) => "Completed ${date}";

  static String m28(minutes) => "${minutes} min";

  static String m29(number, count) => "MODULE ${number} OF ${count}";

  static String m30(label) => "${label} · Planned";

  static String m31(hash, date) => "Rev ${hash} · ${date}";

  static String m32(reason) => "Not saved: ${reason}. Back up to a file to keep it.";

  static String m33(reason) => "The check for updates did not finish: ${reason}.";

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
      "The course content in this app could not be opened. An update of the app restores it. Your progress on this device is kept.",
    ),
    "content_broken_storage_message": MessageLookupByLibrary.simpleMessage(
      "The app could not use its storage for the course content. Your progress on this device is kept.",
    ),
    "content_broken_title": MessageLookupByLibrary.simpleMessage("The course cannot be opened"),
    "content_notice_cache_discarded": MessageLookupByLibrary.simpleMessage(
      "The downloaded content could not be read, so the app removed it and shows the content that came with this version. Check for updates in Settings to download it again.",
    ),
    "content_unreadable": MessageLookupByLibrary.simpleMessage(
      "This part of the course could not be read on this device. Restart the app to reload it.",
    ),
    "data_back_up": MessageLookupByLibrary.simpleMessage("Back up to a file"),
    "data_backed_up": m8,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "The backup file could not be written. Nothing was marked as backed up.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "Your progress is saved on this device only. A backup file keeps it safe if the app\'s data is cleared, and moves it to another device or to the website.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Reset. The time to undo it has passed."),
    "data_reset_counting": m9,
    "data_reset_not_finished": MessageLookupByLibrary.simpleMessage(
      "The reset did not finish: the app could not delete its files. The progress on this device is unchanged.",
    ),
    "data_restore": MessageLookupByLibrary.simpleMessage("Restore from a file"),
    "data_restore_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing was changed. That file holds no progress; only a backup file does.",
    ),
    "data_restore_malformed": MessageLookupByLibrary.simpleMessage(
      "That file is not a backup the app or the website wrote. Nothing was changed.",
    ),
    "data_restore_newer": MessageLookupByLibrary.simpleMessage(
      "That file was written by a newer version of the app or the website. Update the app, then restore it again.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("That file could not be opened."),
    "data_restored": MessageLookupByLibrary.simpleMessage("Restored from the file."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("NOTHING RECORDED ON THIS DEVICE"),
    "data_tally_states": m10,
    "data_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "duration_hours": m11,
    "duration_hours_minutes": m12,
    "duration_minutes": m13,
    "erase_backup_statement": MessageLookupByLibrary.simpleMessage(
      "A device backup may still hold an earlier copy of your progress.",
    ),
    "erase_confirm": MessageLookupByLibrary.simpleMessage("Erase all data"),
    "erase_field_label": MessageLookupByLibrary.simpleMessage("Type ERASE to confirm"),
    "erase_keep": MessageLookupByLibrary.simpleMessage("Keep my data"),
    "erase_mark": MessageLookupByLibrary.simpleMessage("Erase"),
    "erase_scope": MessageLookupByLibrary.simpleMessage(
      "This removes the record from this device, including the copy set aside from a version of the app this one could not read.",
    ),
    "erase_title": MessageLookupByLibrary.simpleMessage("Erase all progress on this device?"),
    "error_link_open_failed": m14,
    "level_completed": m15,
    "level_completed_pending": m16,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("General notes"),
    "level_module_count": m17,
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
    "progress_complete_module": m18,
    "progress_every_module": m19,
    "progress_level_dial": m20,
    "progress_module_link": m21,
    "progress_state_complete": MessageLookupByLibrary.simpleMessage("Complete"),
    "progress_state_not_yet": MessageLookupByLibrary.simpleMessage("Not yet"),
    "progress_tab_count": m22,
    "progress_tabs_label": MessageLookupByLibrary.simpleMessage("Progress by track"),
    "progress_title": MessageLookupByLibrary.simpleMessage("Your progress"),
    "quarantine_copy_not_written": MessageLookupByLibrary.simpleMessage(
      "The copy could not be written. The set-aside record is unchanged.",
    ),
    "quarantine_copy_saved": MessageLookupByLibrary.simpleMessage("Saved a copy of the set-aside record."),
    "quarantine_delete": MessageLookupByLibrary.simpleMessage("Delete it"),
    "quarantine_delete_body": MessageLookupByLibrary.simpleMessage(
      "This version of the app cannot read it. Deleting it cannot be undone.",
    ),
    "quarantine_delete_confirm": MessageLookupByLibrary.simpleMessage("Delete"),
    "quarantine_delete_title": MessageLookupByLibrary.simpleMessage("Delete the set-aside record?"),
    "quarantine_keep": MessageLookupByLibrary.simpleMessage("Keep it"),
    "quarantine_kept_note": MessageLookupByLibrary.simpleMessage(
      "An earlier launch could not read the stored progress. Its bytes are kept on this device unchanged.",
    ),
    "quarantine_kept_readout": MessageLookupByLibrary.simpleMessage("A STORED RECORD IS SET ASIDE"),
    "quarantine_label": MessageLookupByLibrary.simpleMessage("Record status"),
    "quarantine_malformed_note": MessageLookupByLibrary.simpleMessage(
      "The stored record is not a shape this version of the app can read. It has been copied aside on this device unchanged rather than discarded, and nothing has been written over it.",
    ),
    "quarantine_malformed_readout": MessageLookupByLibrary.simpleMessage(
      "PROGRESS THIS VERSION OF THE APP COULD NOT READ. NOT READ.",
    ),
    "quarantine_newer_note": MessageLookupByLibrary.simpleMessage(
      "Update the app to read it. The stored record is kept on this device unchanged.",
    ),
    "quarantine_newer_readout": MessageLookupByLibrary.simpleMessage(
      "PROGRESS WRITTEN BY A NEWER VERSION OF THE APP. NOT READ.",
    ),
    "quarantine_save_copy": MessageLookupByLibrary.simpleMessage("Save a copy"),
    "quiz_back_to_questions": MessageLookupByLibrary.simpleMessage("Back to the questions"),
    "quiz_correct": MessageLookupByLibrary.simpleMessage("Correct."),
    "quiz_next": MessageLookupByLibrary.simpleMessage("Next"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quiz_progress": m23,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", correct"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", not correct"),
    "quiz_score_count": m24,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("answered correctly"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("See results"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "quiz_subtitle": m25,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Questions on this module"),
    "quiz_wrong": m26,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Partly written"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Schedule of parts only"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Before you start"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Close"),
    "reader_completed_on": m27,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Module completion"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("Contents"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("End of the course"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Mark this module as complete"),
    "reader_minutes": m28,
    "reader_module_of": m29,
    "reader_next": MessageLookupByLibrary.simpleMessage("Next"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("The For Everyone version of this module is planned."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("What you will be able to do"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("On this page"),
    "reader_pager_planned": m30,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Read it For Engineers"),
    "reader_revision": m31,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Description"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Item"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Schedule of parts"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("See what is written For Everyone"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Start of the course"),
    "record_not_saved": m32,
    "record_not_saved_blocked": MessageLookupByLibrary.simpleMessage("the app could not write its file"),
    "record_not_saved_quota": MessageLookupByLibrary.simpleMessage("this device has no space left"),
    "record_not_saved_too_large": MessageLookupByLibrary.simpleMessage("the record is larger than the app will write"),
    "restore_confirm_effect": MessageLookupByLibrary.simpleMessage(
      "Restoring replaces it with the progress in the file.",
    ),
    "restore_confirm_holds": MessageLookupByLibrary.simpleMessage("On this device now:"),
    "restore_confirm_replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "restore_confirm_title": MessageLookupByLibrary.simpleMessage("Replace the progress on this device?"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settings_about": MessageLookupByLibrary.simpleMessage("About"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "settings_content": MessageLookupByLibrary.simpleMessage("Content"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("Version"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Developer console"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Licences"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Published"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Checking for updates"),
    "settings_refresh_failed": m33,
    "settings_refresh_idle": MessageLookupByLibrary.simpleMessage("Not checked since the app started"),
    "settings_refresh_needs_app_update": MessageLookupByLibrary.simpleMessage(
      "Newer content needs a newer version of the app. Update the app to get it.",
    ),
    "settings_refresh_reason_checksum": MessageLookupByLibrary.simpleMessage(
      "a downloaded file did not match its checksum",
    ),
    "settings_refresh_reason_format": MessageLookupByLibrary.simpleMessage(
      "the website sent content this version of the app cannot read",
    ),
    "settings_refresh_reason_http_status": MessageLookupByLibrary.simpleMessage("the website answered with an error"),
    "settings_refresh_reason_network": MessageLookupByLibrary.simpleMessage("no connection to the website"),
    "settings_refresh_reason_storage": MessageLookupByLibrary.simpleMessage("the app could not write to its storage"),
    "settings_refresh_reason_stored": MessageLookupByLibrary.simpleMessage("the stored content could not be read"),
    "settings_refresh_up_to_date": MessageLookupByLibrary.simpleMessage("Up to date"),
    "settings_refresh_updated": MessageLookupByLibrary.simpleMessage("Updated to the latest content"),
    "settings_source": MessageLookupByLibrary.simpleMessage("Source"),
    "settings_source_bundled": MessageLookupByLibrary.simpleMessage("Bundled with the app"),
    "settings_source_downloaded": MessageLookupByLibrary.simpleMessage("Downloaded from the website"),
    "track_switch_label": MessageLookupByLibrary.simpleMessage("Track"),
  };
}
