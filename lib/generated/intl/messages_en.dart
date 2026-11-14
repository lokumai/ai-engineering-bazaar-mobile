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

  static String m0(robot, ground) => "${robot}, ${ground}";

  static String m1(language) => "${language} code";

  static String m2(number) => "FIG. ${number}";

  static String m3(number) => "TBL. ${number}";

  static String m4(number) => "Table ${number}";

  static String m5(start, end) => "${start} to ${end}";

  static String m6(start) => "${start} to now";

  static String m7(title) => "The caravan at ${title}";

  static String m8(index, count) => "Stop ${index} of ${count}";

  static String m9(level) => "Strength ${level} of 5";

  static String m10(count) => "${Intl.plural(count, one: '1 trend', other: '${count} trends')}";

  static String m11(minutes) => "${minutes} min";

  static String m12(title) => "Complete ${title}";

  static String m13(approved, total) => "${approved}/${total}";

  static String m14(count) => "${Intl.plural(count, one: '1 result', other: '${count} results')}";

  static String m15(query) => "Nothing found for “${query}”.";

  static String m16(count) => "the first ${count} shown";

  static String m17(day) => "Backed up ${day}";

  static String m18(seconds) =>
      "${Intl.plural(seconds, one: 'Reset. You can undo it for 1 second.', other: 'Reset. You can undo it for ${seconds} seconds.')}";

  static String m19(count) => "${Intl.plural(count, one: '1 module state', other: '${count} module states')}";

  static String m20(hours) => "~${hours} h";

  static String m21(hours, minutes) => "~${hours} h ${minutes} min";

  static String m22(minutes) => "~${minutes} min";

  static String m23(url) => "Could not open ${url}";

  static String m24(count, first) =>
      "The course is set out in ${count} levels, starting with ${first}. Begin with the first and move on when you are ready.";

  static String m25(percent) => "${percent} % read";

  static String m26(minutes, words) => "${minutes} min · ${words} words";

  static String m27(approved, total) => "${approved}/${total} completed";

  static String m28(total) => "--/${total} completed";

  static String m29(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  static String m30(count) => "${Intl.plural(count, one: 'knows 1 word', other: 'knows ${count} words')}";

  static String m31(level) => "Level ${level}";

  static String m32(value) => "loss ${value}";

  static String m33(level) => "read a module for level ${level}";

  static String m34(count) =>
      "${Intl.plural(count, one: '1 finished module waiting', other: '${count} finished modules waiting')}";

  static String m35(words) => "It says: ${words}";

  static String m36(level) => "Apprentice, level ${level}. Tap to pet it.";

  static String m37(count, level) => "${count} to level ${level}";

  static String m38(count) => "${Intl.plural(count, one: '1 token', other: '${count} tokens')}";

  static String m39(count) => "${Intl.plural(count, one: '1 quiz', other: '${count} quizzes')}";

  static String m40(taken, total) => "${taken} of ${total} taken";

  static String m41(index, count) => "Question ${index} of ${count}";

  static String m42(previous, best, total) => "The time before: ${previous} of ${total}. Best: ${best} of ${total}.";

  static String m43(score, total) => "${score} of ${total}";

  static String m44(last, best, total) => "Last ${last} of ${total} · best ${best} of ${total}";

  static String m45(count) => "${count} questions on the main points of this module";

  static String m46(letter) => "Not this one. The answer is ${letter}.";

  static String m47(date) => "Completed ${date}";

  static String m48(position, total) => "Match ${position} of ${total}";

  static String m49(minutes) => "${minutes} min";

  static String m50(number, count) => "MODULE ${number} OF ${count}";

  static String m51(label) => "${label} · Planned";

  static String m52(hash, date) => "Rev ${hash} · ${date}";

  static String m53(reason) => "Not saved: ${reason}. Back up to a file to keep it.";

  static String m54(reason) => "The check for updates did not finish: ${reason}.";

  static String m55(name, level) => "${name}, unlocks at level ${level}";

  static String m56(name) => "${name}, worn";

  static String m57(hat, head, body) => "The robot: ${hat}, ${head}, ${body}";

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
    "app_icon_ground": MessageLookupByLibrary.simpleMessage("Ground"),
    "app_icon_name": m0,
    "app_icon_note_android": MessageLookupByLibrary.simpleMessage(
      "The new icon reaches the home screen when you leave the app. Some phones then take its shortcut off the home screen; the app list shows the new icon. With themed icons on, the phone draws every icon in its own colours.",
    ),
    "app_icon_note_ios": MessageLookupByLibrary.simpleMessage("The phone confirms the new icon with a message."),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "appearance_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "appearance_light": MessageLookupByLibrary.simpleMessage("Light"),
    "block_code_label": m1,
    "block_figure_caption": m2,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program output"),
    "block_table_caption": m3,
    "block_table_region": m4,
    "block_unknown": MessageLookupByLibrary.simpleMessage("This part needs a newer version of the app."),
    "caravan_all_trends": MessageLookupByLibrary.simpleMessage("All trends"),
    "caravan_all_years": MessageLookupByLibrary.simpleMessage("All years"),
    "caravan_hint": MessageLookupByLibrary.simpleMessage("Swipe the card, drag the road or tap a stall to travel."),
    "caravan_in_course": MessageLookupByLibrary.simpleMessage("In the course"),
    "caravan_next": MessageLookupByLibrary.simpleMessage("Next stop"),
    "caravan_no_trend": MessageLookupByLibrary.simpleMessage("No trend matches."),
    "caravan_period": m5,
    "caravan_period_open": m6,
    "caravan_previous": MessageLookupByLibrary.simpleMessage("Previous stop"),
    "caravan_reading": MessageLookupByLibrary.simpleMessage("To read"),
    "caravan_sample_articles": MessageLookupByLibrary.simpleMessage("Sample article"),
    "caravan_sample_badge": MessageLookupByLibrary.simpleMessage("Sample"),
    "caravan_sample_notice": MessageLookupByLibrary.simpleMessage(
      "Content is coming soon. Until then these trends are sample data.",
    ),
    "caravan_sample_repositories": MessageLookupByLibrary.simpleMessage("Sample repository"),
    "caravan_sample_tools": MessageLookupByLibrary.simpleMessage("Sample tool"),
    "caravan_sample_videos": MessageLookupByLibrary.simpleMessage("Sample video"),
    "caravan_search": MessageLookupByLibrary.simpleMessage("Search the trends"),
    "caravan_stage_label": m7,
    "caravan_stop_of": m8,
    "caravan_strength": MessageLookupByLibrary.simpleMessage("Strength"),
    "caravan_strength_of": m9,
    "caravan_strip_label": MessageLookupByLibrary.simpleMessage("Where the caravan is"),
    "caravan_tour": MessageLookupByLibrary.simpleMessage("Tour the road"),
    "caravan_tour_stop": MessageLookupByLibrary.simpleMessage("Stop the tour"),
    "caravan_trend_count": m10,
    "card_description": MessageLookupByLibrary.simpleMessage("Description"),
    "card_length": MessageLookupByLibrary.simpleMessage("Length"),
    "card_length_minutes": m11,
    "card_requires": MessageLookupByLibrary.simpleMessage("Requires"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Nothing"),
    "catalog_complete_module": m12,
    "catalog_filter_completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "catalog_level_dial": m13,
    "catalog_search_clear": MessageLookupByLibrary.simpleMessage("Clear the search"),
    "catalog_search_count": m14,
    "catalog_search_hint": MessageLookupByLibrary.simpleMessage("Search the modules"),
    "catalog_search_none": m15,
    "catalog_search_shown": m16,
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
    "data_backed_up": m17,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "The backup file could not be written. Nothing was marked as backed up.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "Your progress is saved on this device only. A backup file keeps it safe if the app\'s data is cleared, and moves it to another device or to the website.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Reset. The time to undo it has passed."),
    "data_reset_counting": m18,
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
    "data_tally_states": m19,
    "data_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "diagram_expand": MessageLookupByLibrary.simpleMessage("Open the diagram full screen"),
    "duration_hours": m20,
    "duration_hours_minutes": m21,
    "duration_minutes": m22,
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
    "error_link_open_failed": m23,
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
    "guide_levels": m24,
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
    "home_read_percent": m25,
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
    "length_minutes_words": m26,
    "level_completed": m27,
    "level_completed_pending": m28,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("General notes"),
    "level_module_count": m29,
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
    "outfit_body_astronaut": MessageLookupByLibrary.simpleMessage("Space suit"),
    "outfit_body_classic": MessageLookupByLibrary.simpleMessage("Classic"),
    "outfit_body_hoodie": MessageLookupByLibrary.simpleMessage("Hoodie"),
    "outfit_body_kaftan": MessageLookupByLibrary.simpleMessage("Kaftan"),
    "outfit_body_lab_coat": MessageLookupByLibrary.simpleMessage("Lab coat"),
    "outfit_body_suit": MessageLookupByLibrary.simpleMessage("Suit and bow tie"),
    "outfit_body_vest": MessageLookupByLibrary.simpleMessage("Embroidered vest"),
    "outfit_hat_antenna": MessageLookupByLibrary.simpleMessage("Antenna"),
    "outfit_hat_beanie": MessageLookupByLibrary.simpleMessage("Beanie"),
    "outfit_hat_crown": MessageLookupByLibrary.simpleMessage("Crown"),
    "outfit_hat_fez": MessageLookupByLibrary.simpleMessage("Fez"),
    "outfit_hat_mortarboard": MessageLookupByLibrary.simpleMessage("Graduation cap"),
    "outfit_hat_top_hat": MessageLookupByLibrary.simpleMessage("Top hat"),
    "outfit_hat_turban": MessageLookupByLibrary.simpleMessage("Turban"),
    "outfit_hat_wizard": MessageLookupByLibrary.simpleMessage("Wizard\'s hat"),
    "outfit_head_classic": MessageLookupByLibrary.simpleMessage("Classic screen"),
    "outfit_head_dome": MessageLookupByLibrary.simpleMessage("Round head"),
    "outfit_head_ears": MessageLookupByLibrary.simpleMessage("Cat ears"),
    "outfit_head_tv": MessageLookupByLibrary.simpleMessage("Old television"),
    "outfit_head_visor": MessageLookupByLibrary.simpleMessage("Space helmet"),
    "pocket_ask": MessageLookupByLibrary.simpleMessage("Chat"),
    "pocket_feed": MessageLookupByLibrary.simpleMessage("Feed tokens"),
    "pocket_hallucinating": MessageLookupByLibrary.simpleMessage("hallucinating"),
    "pocket_known": m30,
    "pocket_lede": MessageLookupByLibrary.simpleMessage("A toy model that can talk nonsense."),
    "pocket_level": m31,
    "pocket_level_word": MessageLookupByLibrary.simpleMessage("level"),
    "pocket_loss": m32,
    "pocket_loss_empty": MessageLookupByLibrary.simpleMessage("The curve starts with the first feed."),
    "pocket_loss_title": MessageLookupByLibrary.simpleMessage("Training loss"),
    "pocket_next_module": m33,
    "pocket_read_module": MessageLookupByLibrary.simpleMessage("Read a module you finished"),
    "pocket_read_none": MessageLookupByLibrary.simpleMessage("Finish a module, and it can read it too."),
    "pocket_read_waiting": m34,
    "pocket_reset": MessageLookupByLibrary.simpleMessage("Start over"),
    "pocket_reset_body": MessageLookupByLibrary.simpleMessage(
      "It forgets every token it read and starts again at level 0. The course and its progress stay as they are.",
    ),
    "pocket_reset_keep": MessageLookupByLibrary.simpleMessage("Keep it"),
    "pocket_reset_title": MessageLookupByLibrary.simpleMessage("Start the apprentice over?"),
    "pocket_says": m35,
    "pocket_stage_label": m36,
    "pocket_status_asleep": MessageLookupByLibrary.simpleMessage("Asleep. Tap it to wake it."),
    "pocket_status_cold": MessageLookupByLibrary.simpleMessage("Cold: it says its likeliest words, every time."),
    "pocket_status_hallucinating": MessageLookupByLibrary.simpleMessage(
      "Too hot: it hallucinates. Turn the temperature down.",
    ),
    "pocket_status_hungry": MessageLookupByLibrary.simpleMessage("Hungry: not fed for hours."),
    "pocket_status_newborn": MessageLookupByLibrary.simpleMessage("New: it knows no words yet. Feed it some tokens."),
    "pocket_status_overfit": MessageLookupByLibrary.simpleMessage(
      "Overfitted: it learnt the tokens by heart and repeats them. Let it rest a few seconds.",
    ),
    "pocket_status_recovered": MessageLookupByLibrary.simpleMessage("Rested, and ready to learn again."),
    "pocket_temperature": MessageLookupByLibrary.simpleMessage("Temperature"),
    "pocket_title": MessageLookupByLibrary.simpleMessage("Apprentice"),
    "pocket_to_next": m37,
    "pocket_tokens": m38,
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
    "quiz_list_count": m39,
    "quiz_list_taken": m40,
    "quiz_next": MessageLookupByLibrary.simpleMessage("Next"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quiz_progress": m41,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", correct"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", not correct"),
    "quiz_score_before": m42,
    "quiz_score_count": m43,
    "quiz_score_line": m44,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("answered correctly"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("See results"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "quiz_subtitle": m45,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Questions on this module"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage(
      "This quiz could not be opened. Close it and try again later.",
    ),
    "quiz_wrong": m46,
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Partly written"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Schedule of parts only"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Before you start"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Close"),
    "reader_completed_on": m47,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Module completion"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("Contents"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("End of the course"),
    "reader_failed": MessageLookupByLibrary.simpleMessage(
      "This module could not be read on this device. Try again, or restart the app.",
    ),
    "reader_find_close": MessageLookupByLibrary.simpleMessage("Stop marking the search"),
    "reader_find_next": MessageLookupByLibrary.simpleMessage("Next match"),
    "reader_find_position": m48,
    "reader_find_previous": MessageLookupByLibrary.simpleMessage("Previous match"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Mark this module as complete"),
    "reader_minutes": m49,
    "reader_module_of": m50,
    "reader_next": MessageLookupByLibrary.simpleMessage("Next"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("The For Everyone version of this module is planned."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("What you will be able to do"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("On this page"),
    "reader_pager_planned": m51,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Read it For Engineers"),
    "reader_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "reader_revision": m52,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Description"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Item"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Schedule of parts"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("See what is written For Everyone"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Start of the course"),
    "record_not_saved": m53,
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
    "settings_customize": MessageLookupByLibrary.simpleMessage("Customize"),
    "settings_data": MessageLookupByLibrary.simpleMessage("Your progress"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Developer console"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Language"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Licences"),
    "settings_off": MessageLookupByLibrary.simpleMessage("Off"),
    "settings_on": MessageLookupByLibrary.simpleMessage("On"),
    "settings_pocket_button": MessageLookupByLibrary.simpleMessage("Apprentice"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("Privacy and legal"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Published"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("Reading"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Checking for updates"),
    "settings_refresh_failed": m54,
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
    "settings_robot": MessageLookupByLibrary.simpleMessage("Wardrobe"),
    "settings_source": MessageLookupByLibrary.simpleMessage("Source"),
    "settings_source_bundled": MessageLookupByLibrary.simpleMessage("Bundled with the app"),
    "settings_source_downloaded": MessageLookupByLibrary.simpleMessage("Downloaded from the website"),
    "settings_story": MessageLookupByLibrary.simpleMessage("The story of the Bazaar"),
    "settings_track": MessageLookupByLibrary.simpleMessage("Audience"),
    "track_engineers": MessageLookupByLibrary.simpleMessage("For Engineers"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("For Everyone"),
    "wardrobe_body": MessageLookupByLibrary.simpleMessage("Body"),
    "wardrobe_hat": MessageLookupByLibrary.simpleMessage("Hat"),
    "wardrobe_head": MessageLookupByLibrary.simpleMessage("Head"),
    "wardrobe_item_locked": m55,
    "wardrobe_item_worn": m56,
    "wardrobe_note": MessageLookupByLibrary.simpleMessage(
      "Each level of the apprentice unlocks something new to wear.",
    ),
    "wardrobe_preview": m57,
    "welcome_start": MessageLookupByLibrary.simpleMessage("Start learning"),
    "welcome_story_continue": MessageLookupByLibrary.simpleMessage("Start learning"),
    "welcome_to_story": MessageLookupByLibrary.simpleMessage("Our story"),
    "welcome_track_engineers": MessageLookupByLibrary.simpleMessage(
      "The technical modules: how each part works, with the code and numbers.",
    ),
    "welcome_track_everyone": MessageLookupByLibrary.simpleMessage(
      "The same modules in plain words, for readers with no technical background.",
    ),
    "welcome_track_title": MessageLookupByLibrary.simpleMessage("How would you like to read?"),
  };
}
