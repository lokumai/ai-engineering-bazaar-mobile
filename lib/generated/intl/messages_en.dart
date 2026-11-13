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

  static String m5(title) => "Complete ${title}";

  static String m6(approved, total) => "${approved}/${total}";

  static String m7(count) => "${Intl.plural(count, one: '1 result', other: '${count} results')}";

  static String m8(query) => "Nothing found for “${query}”.";

  static String m9(count) => "the first ${count} shown";

  static String m10(day) => "Backed up ${day}";

  static String m11(seconds) =>
      "${Intl.plural(seconds, one: 'Reset. You can undo it for 1 second.', other: 'Reset. You can undo it for ${seconds} seconds.')}";

  static String m12(count) => "${Intl.plural(count, one: '1 module state', other: '${count} module states')}";

  static String m13(hours) => "~${hours} h";

  static String m14(hours, minutes) => "~${hours} h ${minutes} min";

  static String m15(minutes) => "~${minutes} min";

  static String m16(url) => "Could not open ${url}";

  static String m17(count, first) =>
      "The course is set out in ${count} levels, starting with ${first}. Begin with the first and move on when you are ready.";

  static String m18(percent) => "${percent} % read";

  static String m19(minutes, words) => "${minutes} min · ${words} words";

  static String m20(approved, total) => "${approved}/${total} completed";

  static String m21(total) => "--/${total} completed";

  static String m22(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  static String m23(count) => "${Intl.plural(count, one: '1 quiz', other: '${count} quizzes')}";

  static String m24(taken, total) => "${taken} of ${total} taken";

  static String m25(index, count) => "Question ${index} of ${count}";

  static String m26(previous, best, total) => "The time before: ${previous} of ${total}. Best: ${best} of ${total}.";

  static String m27(score, total) => "${score} of ${total}";

  static String m28(last, best, total) => "Last ${last} of ${total} · best ${best} of ${total}";

  static String m29(count) => "${count} questions on the main points of this module";

  static String m30(letter) => "Not this one. The answer is ${letter}.";

  static String m31(date) => "Completed ${date}";

  static String m32(position, total) => "Match ${position} of ${total}";

  static String m33(minutes) => "${minutes} min";

  static String m34(number, count) => "MODULE ${number} OF ${count}";

  static String m35(label) => "${label} · Planned";

  static String m36(hash, date) => "Rev ${hash} · ${date}";

  static String m37(reason) => "Not saved: ${reason}. Back up to a file to keep it.";

  static String m38(reason) => "The check for updates did not finish: ${reason}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about_close": MessageLookupByLibrary.simpleMessage("Close"),
    "about_english": MessageLookupByLibrary.simpleMessage("The story is written in English."),
    "about_failed": MessageLookupByLibrary.simpleMessage(
      "The story could not be opened. Check for updates, then open it again.",
    ),
    "about_next": MessageLookupByLibrary.simpleMessage("Next"),
    "about_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "about_skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "app_icon_cream": MessageLookupByLibrary.simpleMessage("Cream"),
    "app_icon_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "app_icon_default": MessageLookupByLibrary.simpleMessage("Default"),
    "app_icon_ink": MessageLookupByLibrary.simpleMessage("Ink"),
    "app_icon_night_gold": MessageLookupByLibrary.simpleMessage("Night gold"),
    "app_icon_night_sea": MessageLookupByLibrary.simpleMessage("Night sea"),
    "app_icon_noir": MessageLookupByLibrary.simpleMessage("Noir"),
    "app_icon_note_android": MessageLookupByLibrary.simpleMessage(
      "The new icon reaches the home screen when you leave the app. Some phones then take its shortcut off the home screen; the app list shows it in the new colours. With themed icons on, the phone draws every icon in its own colours.",
    ),
    "app_icon_note_ios": MessageLookupByLibrary.simpleMessage("The phone confirms the new icon with a message."),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "appearance_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "appearance_light": MessageLookupByLibrary.simpleMessage("Light"),
    "block_code_label": m0,
    "block_figure_caption": m1,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program output"),
    "block_table_caption": m2,
    "block_table_region": m3,
    "block_unknown": MessageLookupByLibrary.simpleMessage("This part needs a newer version of the app."),
    "caravan_soon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "caravan_soon_body": MessageLookupByLibrary.simpleMessage(
      "A timeline of what was trending in AI engineering, season by season. Until it arrives, the catalog is open.",
    ),
    "caravan_soon_title": MessageLookupByLibrary.simpleMessage("The Caravan is on its way"),
    "card_description": MessageLookupByLibrary.simpleMessage("Description"),
    "card_length": MessageLookupByLibrary.simpleMessage("Length"),
    "card_length_minutes": m4,
    "card_requires": MessageLookupByLibrary.simpleMessage("Requires"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Nothing"),
    "catalog_complete_module": m5,
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "catalog_level_dial": m6,
    "catalog_search_clear": MessageLookupByLibrary.simpleMessage("Clear the search"),
    "catalog_search_count": m7,
    "catalog_search_hint": MessageLookupByLibrary.simpleMessage("Search the modules"),
    "catalog_search_none": m8,
    "catalog_search_shown": m9,
    "catalog_state_complete": MessageLookupByLibrary.simpleMessage("Complete"),
    "catalog_state_not_yet": MessageLookupByLibrary.simpleMessage("Not yet"),
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
    "data_back_up": MessageLookupByLibrary.simpleMessage("Back up"),
    "data_backed_up": m10,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "The backup file could not be written. Nothing was marked as backed up.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "Your progress is saved on this device only. A backup file keeps it safe if the app\'s data is cleared, and moves it to another device or to the website.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Reset. The time to undo it has passed."),
    "data_reset_counting": m11,
    "data_reset_not_finished": MessageLookupByLibrary.simpleMessage(
      "The reset did not finish: the app could not delete its files. The progress on this device is unchanged.",
    ),
    "data_restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "data_restore_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing was changed. That file holds no progress; only a backup file does.",
    ),
    "data_restore_malformed": MessageLookupByLibrary.simpleMessage(
      "That file is not a backup the app or the website wrote. Nothing was changed.",
    ),
    "data_restore_newer": MessageLookupByLibrary.simpleMessage(
      "That file was written by a newer version of the app or the website. Update the app, then restore it again.",
    ),
    "data_restore_not_done": MessageLookupByLibrary.simpleMessage(
      "The file was not restored, because a reset was under way. Try again.",
    ),
    "data_restore_too_large": MessageLookupByLibrary.simpleMessage(
      "That backup is larger than the app can keep. Nothing was changed.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("That file could not be opened."),
    "data_restored": MessageLookupByLibrary.simpleMessage("Restored from the file."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("NOTHING RECORDED ON THIS DEVICE"),
    "data_tally_states": m12,
    "data_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "diagram_expand": MessageLookupByLibrary.simpleMessage("Open the diagram full screen"),
    "duration_hours": m13,
    "duration_hours_minutes": m14,
    "duration_minutes": m15,
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
    "erase_scores": MessageLookupByLibrary.simpleMessage("The quiz scores on this device are erased too."),
    "erase_title": MessageLookupByLibrary.simpleMessage("Erase all progress on this device?"),
    "erase_word": MessageLookupByLibrary.simpleMessage("ERASE"),
    "error_link_open_failed": m16,
    "feedback_failed": MessageLookupByLibrary.simpleMessage("The report was not sent. Try again later."),
    "feedback_field": MessageLookupByLibrary.simpleMessage("What happened"),
    "feedback_intro": MessageLookupByLibrary.simpleMessage(
      "Write what went wrong. The report goes to Sentry with the app\'s version and the device\'s model and system, and with no name or email. The app masks emails and other personal details in it before it leaves the device.",
    ),
    "feedback_send": MessageLookupByLibrary.simpleMessage("Send"),
    "feedback_sending": MessageLookupByLibrary.simpleMessage("Sending"),
    "feedback_sent": MessageLookupByLibrary.simpleMessage("The report is sent."),
    "feedback_title": MessageLookupByLibrary.simpleMessage("Report a problem"),
    "guide_complete": MessageLookupByLibrary.simpleMessage(
      "At the end of a module, mark it complete. The catalog shows what you have read, and Home shows what comes next.",
    ),
    "guide_complete_title": MessageLookupByLibrary.simpleMessage("Mark what you finish"),
    "guide_levels": m17,
    "guide_levels_title": MessageLookupByLibrary.simpleMessage("Level by level"),
    "guide_modules": MessageLookupByLibrary.simpleMessage(
      "Each module is a 20 to 30 minute read, with diagrams and code. Some end with a few questions to check yourself.",
    ),
    "guide_modules_title": MessageLookupByLibrary.simpleMessage("Short modules"),
    "guide_offline": MessageLookupByLibrary.simpleMessage(
      "The whole course is in the app and reads without a connection. There is no account: your progress stays on this phone.",
    ),
    "guide_offline_title": MessageLookupByLibrary.simpleMessage("On this device, offline"),
    "guide_title": MessageLookupByLibrary.simpleMessage("How the bazaar works"),
    "home_after": MessageLookupByLibrary.simpleMessage("After that"),
    "home_all_complete": MessageLookupByLibrary.simpleMessage("Every written module is complete."),
    "home_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "home_continue_reading": MessageLookupByLibrary.simpleMessage("Continue reading"),
    "home_offline_body": MessageLookupByLibrary.simpleMessage(
      "It reads without a connection. At every start the app asks the site for a newer version.",
    ),
    "home_offline_title": MessageLookupByLibrary.simpleMessage("The course is on this device"),
    "home_open_module": MessageLookupByLibrary.simpleMessage("Open the module"),
    "home_path": MessageLookupByLibrary.simpleMessage("Your path"),
    "home_practice": MessageLookupByLibrary.simpleMessage("Quizzes to practise"),
    "home_practice_lede": MessageLookupByLibrary.simpleMessage("Quizzes from the modules you completed."),
    "home_read_percent": m18,
    "home_see_catalog": MessageLookupByLibrary.simpleMessage("See the whole catalog"),
    "home_up_next": MessageLookupByLibrary.simpleMessage("Up next"),
    "image_expand": MessageLookupByLibrary.simpleMessage("Open the image full screen"),
    "image_replay": MessageLookupByLibrary.simpleMessage("Replay"),
    "legal_address": MessageLookupByLibrary.simpleMessage("Address"),
    "legal_email": MessageLookupByLibrary.simpleMessage("Email"),
    "legal_images": MessageLookupByLibrary.simpleMessage(
      "Some images come from articles and other public sources, with sincere thanks to their authors. They remain the property of their owners, no rights in them are claimed, and they are shown only to explain the point next to them. The owner of an image or a mark shown here can write to the address below to have it credited or removed, whichever they prefer.",
    ),
    "legal_licence": MessageLookupByLibrary.simpleMessage(
      "The project\'s MIT licence covers its code and its content. It does not cover third-party marks or images.",
    ),
    "legal_licence_link": MessageLookupByLibrary.simpleMessage("MIT licence"),
    "legal_marks": MessageLookupByLibrary.simpleMessage(
      "Company names and logos shown in the modules belong to their owners. They appear only to say which company is meant, and they do not mean that the company endorses this app.",
    ),
    "legal_marks_title": MessageLookupByLibrary.simpleMessage("Third-party marks and images"),
    "legal_mersis": MessageLookupByLibrary.simpleMessage("MERSİS no."),
    "legal_owner": MessageLookupByLibrary.simpleMessage("Owner"),
    "legal_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "legal_title": MessageLookupByLibrary.simpleMessage("Legal"),
    "length_minutes_words": m19,
    "level_completed": m20,
    "level_completed_pending": m21,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("General notes"),
    "level_module_count": m22,
    "loading": MessageLookupByLibrary.simpleMessage("Loading"),
    "module_planned": MessageLookupByLibrary.simpleMessage("Planned"),
    "nav_caravan": MessageLookupByLibrary.simpleMessage("Caravan"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("Catalog"),
    "nav_home": MessageLookupByLibrary.simpleMessage("Home"),
    "nav_quiz": MessageLookupByLibrary.simpleMessage("Quiz"),
    "nav_settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "not_found_message": MessageLookupByLibrary.simpleMessage(
      "This address is not a module in the curriculum. The catalog lists every one that is.",
    ),
    "not_found_title": MessageLookupByLibrary.simpleMessage("No such module"),
    "open_on_the_web": MessageLookupByLibrary.simpleMessage("Open on the web"),
    "privacy_contact": MessageLookupByLibrary.simpleMessage("For any question about personal data, write to us."),
    "privacy_crash": MessageLookupByLibrary.simpleMessage(
      "When the app crashes, it sends a crash report to Sentry so the fault can be fixed. To follow the app\'s health by version, it also tells Sentry when it opens and closes, how long it took to open and when it froze, with a random number for this installation. None of this holds your name, what you read or your quiz answers. The app masks personal details before they leave the device, and Sentry keeps no IP address. A problem you send under Report a problem goes to Sentry the same way.",
    ),
    "privacy_download": MessageLookupByLibrary.simpleMessage(
      "The app downloads the course from the website, which is hosted on GitHub Pages. GitHub logs and stores the IP address of every visitor for security. This is GitHub\'s record, not ours.",
    ),
    "privacy_github_pages": MessageLookupByLibrary.simpleMessage("What is GitHub Pages?"),
    "privacy_github_statement": MessageLookupByLibrary.simpleMessage("GitHub General Privacy Statement"),
    "privacy_no_data": MessageLookupByLibrary.simpleMessage(
      "This app collects no personal data. It has no account, no analytics and no ads.",
    ),
    "privacy_on_device": MessageLookupByLibrary.simpleMessage(
      "Your progress, your quiz scores and your settings are saved on this device only. You can back them up, restore or erase them under Your progress in Settings.",
    ),
    "privacy_site_note": MessageLookupByLibrary.simpleMessage("The privacy note on the website"),
    "privacy_title": MessageLookupByLibrary.simpleMessage("Privacy"),
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
    "quiz_all_right": MessageLookupByLibrary.simpleMessage("All answers right"),
    "quiz_back_to_module": MessageLookupByLibrary.simpleMessage("Back to the module"),
    "quiz_back_to_questions": MessageLookupByLibrary.simpleMessage("Back to the questions"),
    "quiz_correct": MessageLookupByLibrary.simpleMessage("Correct."),
    "quiz_done": MessageLookupByLibrary.simpleMessage("Done"),
    "quiz_list_count": m23,
    "quiz_list_taken": m24,
    "quiz_next": MessageLookupByLibrary.simpleMessage("Next"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quiz_progress": m25,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", correct"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", not correct"),
    "quiz_score_before": m26,
    "quiz_score_count": m27,
    "quiz_score_line": m28,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("answered correctly"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("See results"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "quiz_subtitle": m29,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Questions on this module"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage(
      "This quiz could not be opened. Close it and try again later.",
    ),
    "quiz_wrong": m30,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Partly written"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Schedule of parts only"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Before you start"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Close"),
    "reader_completed_on": m31,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Module completion"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("Contents"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("End of the course"),
    "reader_failed": MessageLookupByLibrary.simpleMessage(
      "This module could not be read on this device. Try again, or restart the app.",
    ),
    "reader_find_close": MessageLookupByLibrary.simpleMessage("Stop marking the search"),
    "reader_find_next": MessageLookupByLibrary.simpleMessage("Next match"),
    "reader_find_position": m32,
    "reader_find_previous": MessageLookupByLibrary.simpleMessage("Previous match"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Mark this module as complete"),
    "reader_minutes": m33,
    "reader_module_of": m34,
    "reader_next": MessageLookupByLibrary.simpleMessage("Next"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("The For Everyone version of this module is planned."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("What you will be able to do"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("On this page"),
    "reader_pager_planned": m35,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Read it For Engineers"),
    "reader_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "reader_revision": m36,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Description"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Item"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Schedule of parts"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("See what is written For Everyone"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Start of the course"),
    "record_not_saved": m37,
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
    "settings_app_icon": MessageLookupByLibrary.simpleMessage("App icon"),
    "settings_appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "settings_content": MessageLookupByLibrary.simpleMessage("Content"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("Version"),
    "settings_data": MessageLookupByLibrary.simpleMessage("Your progress"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Developer console"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Language"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Licences"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("Privacy and legal"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Published"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("Reading"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Checking for updates"),
    "settings_refresh_failed": m38,
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
    "settings_story": MessageLookupByLibrary.simpleMessage("The story of the Bazaar"),
    "settings_track": MessageLookupByLibrary.simpleMessage("Audience"),
    "track_engineers": MessageLookupByLibrary.simpleMessage("For Engineers"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("For Everyone"),
    "welcome_app_icon_done": MessageLookupByLibrary.simpleMessage("Done"),
    "welcome_start": MessageLookupByLibrary.simpleMessage("Start reading"),
    "welcome_story_continue": MessageLookupByLibrary.simpleMessage("Start learning"),
    "welcome_to_story": MessageLookupByLibrary.simpleMessage("On to the story"),
    "welcome_track_engineers": MessageLookupByLibrary.simpleMessage(
      "The technical modules: how each part works, with the code and the numbers behind it.",
    ),
    "welcome_track_everyone": MessageLookupByLibrary.simpleMessage(
      "The same modules in plain words, for readers with no technical background.",
    ),
    "welcome_track_title": MessageLookupByLibrary.simpleMessage("How would you like to read?"),
  };
}
