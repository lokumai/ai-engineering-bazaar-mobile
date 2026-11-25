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

  static String m5(step, count) => "Card ${step} of ${count}";

  static String m6(start, end) => "${start} to ${end}";

  static String m7(start) => "${start} to now";

  static String m8(title) => "The caravan at ${title}";

  static String m9(index, count) => "Stop ${index} of ${count}";

  static String m10(level) => "Strength ${level} of 5";

  static String m11(count) => "${Intl.plural(count, one: '1 trend', other: '${count} trends')}";

  static String m12(minutes) => "${minutes} min";

  static String m13(title) => "Complete ${title}";

  static String m14(approved, total) => "${approved}/${total}";

  static String m15(count) => "${Intl.plural(count, one: '1 result', other: '${count} results')}";

  static String m16(count) => "${Intl.plural(count, one: '1 match', other: '${count} matches')}";

  static String m17(query) => "Nothing found for “${query}”.";

  static String m18(query) => "Nothing found for “${query}” in this track.";

  static String m19(track) => "In ${track}";

  static String m20(count) => "the first ${count} shown";

  static String m21(day) => "Backed up ${day}";

  static String m22(seconds) =>
      "${Intl.plural(seconds, one: 'Reset. You can undo it for 1 second.', other: 'Reset. You can undo it for ${seconds} seconds.')}";

  static String m23(count) => "${Intl.plural(count, one: '1 module state', other: '${count} module states')}";

  static String m24(hours) => "~${hours} h";

  static String m25(hours, minutes) => "~${hours} h ${minutes} min";

  static String m26(minutes) => "~${minutes} min";

  static String m27(url) => "Could not open ${url}";

  static String m28(count, first) =>
      "The course is set out in ${count} levels, starting with ${first}. Begin with the first and move on when you are ready.";

  static String m29(percent) => "${percent}% read";

  static String m30(minutes, words) => "${minutes} min · ${words} words";

  static String m31(approved, total) => "${approved}/${total} completed";

  static String m32(total) => "--/${total} completed";

  static String m33(approved, total) => "${approved} of ${total} completed";

  static String m34(count) => "${Intl.plural(count, one: '1 module', other: '${count} modules')}";

  static String m35(title) => "Read aloud: ${title}. Open it";

  static String m36(at, count) => "${at} of ${count}";

  static String m37(rate) => "Speed ${rate}";

  static String m38(level) => "Level ${level}";

  static String m39(value) => "loss ${value}";

  static String m40(level) => "read a module for level ${level}";

  static String m41(count) =>
      "${Intl.plural(count, one: '1 finished module waiting', other: '${count} finished modules waiting')}";

  static String m42(words) => "It says: ${words}";

  static String m43(level) => "Apprentice, level ${level}. Tap to pet it.";

  static String m44(count) => "${Intl.plural(count, one: 'module read', other: 'modules read')}";

  static String m45(count) => "${Intl.plural(count, one: 'token eaten', other: 'tokens eaten')}";

  static String m46(count) => "${Intl.plural(count, one: 'word known', other: 'words known')}";

  static String m47(count, level) => "${count} to level ${level}";

  static String m48(count) =>
      "${Intl.plural(count, zero: 'Complete a module first', one: '1 completed module', other: '${count} completed modules')}";

  static String m49(count) => "${Intl.plural(count, zero: 'No terms yet', one: '1 term', other: '${count} terms')}";

  static String m50(right, total) => "${right} of ${total} right last time";

  static String m51(count, minutes) =>
      "${Intl.plural(count, one: '1 card', other: '${count} cards')}, about ${minutes} min";

  static String m52(count) => "${Intl.plural(count, zero: 'None now', one: '1 question', other: '${count} questions')}";

  static String m53(count) => "${Intl.plural(count, one: '1 quiz', other: '${count} quizzes')}";

  static String m54(taken, total) => "${taken} of ${total} taken";

  static String m55(index, count) => "Question ${index} of ${count}";

  static String m56(previous, best, total) => "The time before: ${previous} of ${total}. Best: ${best} of ${total}.";

  static String m57(score, total) => "${score} of ${total}";

  static String m58(count) =>
      "${Intl.plural(count, one: '1 question on the main point of this module', other: '${count} questions on the main points of this module')}";

  static String m59(letter) => "Not this one. The answer is ${letter}.";

  static String m60(date) => "Completed ${date}";

  static String m61(position, total) => "Match ${position} of ${total}";

  static String m62(minutes) => "${minutes} min";

  static String m63(number, count) => "MODULE ${number} OF ${count}";

  static String m64(label) => "${label} · Planned";

  static String m65(hash, date) => "Rev ${hash} · ${date}";

  static String m66(reason) => "Not saved: ${reason}. Back up to a file to keep it.";

  static String m67(step, count) => "Card ${step} of ${count}";

  static String m68(right, total) => "${right} of ${total} right";

  static String m69(section) => "This is in: ${section}";

  static String m70(reason) => "The check for updates did not finish: ${reason}.";

  static String m71(step, count) => "${step} of ${count}";

  static String m72(count) => "${Intl.plural(count, one: '1 module completed', other: '${count} modules completed')}";

  static String m73(count) =>
      "${Intl.plural(count, one: '1 checklist item ticked', other: '${count} checklist items ticked')}";

  static String m74(name, level) => "${name}, unlocks at level ${level}";

  static String m75(name) => "${name}, worn";

  static String m76(hat, head, body) => "The robot: ${hat}, ${head}, ${body}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about_close": MessageLookupByLibrary.simpleMessage("Close"),
    "about_english": MessageLookupByLibrary.simpleMessage("The story is written in English."),
    "about_failed": MessageLookupByLibrary.simpleMessage(
      "The story could not be opened. Open it again later, or update the app.",
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
      "The new icon reaches the home screen when you leave the app. Some devices then take its shortcut off the home screen; the app list shows the new icon. With themed icons on, the device draws every icon in its own colours.",
    ),
    "app_icon_note_ios": MessageLookupByLibrary.simpleMessage("The device confirms the new icon with a message."),
    "app_title": MessageLookupByLibrary.simpleMessage("AI Engineering Bazaar"),
    "appearance_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "appearance_light": MessageLookupByLibrary.simpleMessage("Light"),
    "block_code_copied": MessageLookupByLibrary.simpleMessage("Copied"),
    "block_code_copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "block_code_label": m1,
    "block_figure_caption": m2,
    "block_program_output": MessageLookupByLibrary.simpleMessage("Program output"),
    "block_table_caption": m3,
    "block_table_region": m4,
    "block_unknown": MessageLookupByLibrary.simpleMessage("This part needs a newer version of the app."),
    "brief_end": MessageLookupByLibrary.simpleMessage("That is the module. Its quiz checks what stayed."),
    "brief_next": MessageLookupByLibrary.simpleMessage("Next card"),
    "brief_open_module": MessageLookupByLibrary.simpleMessage("Open the module"),
    "brief_previous": MessageLookupByLibrary.simpleMessage("Previous card"),
    "brief_step": m5,
    "brief_summary": MessageLookupByLibrary.simpleMessage("Summary"),
    "brief_take_quiz": MessageLookupByLibrary.simpleMessage("Take the quiz"),
    "brief_terms": MessageLookupByLibrary.simpleMessage("Key Terms"),
    "caravan_all_trends": MessageLookupByLibrary.simpleMessage("All trends"),
    "caravan_all_years": MessageLookupByLibrary.simpleMessage("All years"),
    "caravan_hint": MessageLookupByLibrary.simpleMessage("Swipe the card, drag the road or tap a stall to travel."),
    "caravan_in_course": MessageLookupByLibrary.simpleMessage("In the course"),
    "caravan_next": MessageLookupByLibrary.simpleMessage("Next stop"),
    "caravan_no_trend": MessageLookupByLibrary.simpleMessage("No trend matches."),
    "caravan_period": m6,
    "caravan_period_open": m7,
    "caravan_previous": MessageLookupByLibrary.simpleMessage("Previous stop"),
    "caravan_search": MessageLookupByLibrary.simpleMessage("Search the trends"),
    "caravan_stage_label": m8,
    "caravan_stop_of": m9,
    "caravan_strength": MessageLookupByLibrary.simpleMessage("Strength"),
    "caravan_strength_of": m10,
    "caravan_strip_label": MessageLookupByLibrary.simpleMessage("Where the caravan is"),
    "caravan_tour": MessageLookupByLibrary.simpleMessage("Tour the road"),
    "caravan_tour_stop": MessageLookupByLibrary.simpleMessage("Stop the tour"),
    "caravan_trend_count": m11,
    "card_description": MessageLookupByLibrary.simpleMessage("Description"),
    "card_length": MessageLookupByLibrary.simpleMessage("Length"),
    "card_length_minutes": m12,
    "card_requires": MessageLookupByLibrary.simpleMessage("Requires"),
    "card_requires_nothing": MessageLookupByLibrary.simpleMessage("Nothing"),
    "catalog_complete_module": m13,
    "catalog_level_dial": m14,
    "catalog_search_all_levels": MessageLookupByLibrary.simpleMessage("All"),
    "catalog_search_clear": MessageLookupByLibrary.simpleMessage("Clear the search"),
    "catalog_search_count": m15,
    "catalog_search_hint": MessageLookupByLibrary.simpleMessage("Search the modules"),
    "catalog_search_levels": MessageLookupByLibrary.simpleMessage("Levels to search"),
    "catalog_search_matches": m16,
    "catalog_search_none": m17,
    "catalog_search_none_here": m18,
    "catalog_search_open_module": MessageLookupByLibrary.simpleMessage("Open the module"),
    "catalog_search_other_track": m19,
    "catalog_search_shown": m20,
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
    "data_backed_up": m21,
    "data_backup_not_written": MessageLookupByLibrary.simpleMessage(
      "The backup file could not be written. Nothing was marked as backed up.",
    ),
    "data_line_text": MessageLookupByLibrary.simpleMessage(
      "Your progress is saved on this device only. A backup file keeps it safe if the app\'s data is cleared, and moves it to another device or to the website.",
    ),
    "data_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "data_reset_closed": MessageLookupByLibrary.simpleMessage("Reset. The time to undo it has passed."),
    "data_reset_counting": m22,
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
    "data_restore_not_saved": MessageLookupByLibrary.simpleMessage(
      "The file is shown, but this device could not save it, so it is gone when the app closes. Free some space and restore it again.",
    ),
    "data_restore_too_large": MessageLookupByLibrary.simpleMessage(
      "That backup is larger than the app can keep. Nothing was changed.",
    ),
    "data_restore_unreadable": MessageLookupByLibrary.simpleMessage("That file could not be opened."),
    "data_restored": MessageLookupByLibrary.simpleMessage("Restored from the file."),
    "data_send_empty": MessageLookupByLibrary.simpleMessage("Nothing to send yet: no module is completed or ticked."),
    "data_send_failed": MessageLookupByLibrary.simpleMessage("The share menu did not open."),
    "data_send_to_website": MessageLookupByLibrary.simpleMessage("Send to the website"),
    "data_send_too_large": MessageLookupByLibrary.simpleMessage("Your progress is too long to fit in a link."),
    "data_tally_nothing": MessageLookupByLibrary.simpleMessage("NOTHING RECORDED ON THIS DEVICE"),
    "data_tally_states": m23,
    "data_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "diagram_expand": MessageLookupByLibrary.simpleMessage("Open the diagram full screen"),
    "duration_hours": m24,
    "duration_hours_minutes": m25,
    "duration_minutes": m26,
    "erase_backup_statement": MessageLookupByLibrary.simpleMessage(
      "A device backup may still hold an earlier copy of your progress.",
    ),
    "erase_confirm": MessageLookupByLibrary.simpleMessage("Erase all progress"),
    "erase_field_label": MessageLookupByLibrary.simpleMessage("Type ERASE to confirm"),
    "erase_keep": MessageLookupByLibrary.simpleMessage("Keep my data"),
    "erase_mark": MessageLookupByLibrary.simpleMessage("Erase"),
    "erase_scope": MessageLookupByLibrary.simpleMessage(
      "This removes the record from this device, including the copy set aside from a version of the app this one could not read.",
    ),
    "erase_scores": MessageLookupByLibrary.simpleMessage(
      "The quiz scores, the Practice history and the places kept in each module, read and heard, are erased on this device too.",
    ),
    "erase_title": MessageLookupByLibrary.simpleMessage("Erase all progress on this device?"),
    "erase_word": MessageLookupByLibrary.simpleMessage("ERASE"),
    "error_link_open_failed": m27,
    "feedback_failed": MessageLookupByLibrary.simpleMessage("The report was not sent. Try again later."),
    "feedback_field": MessageLookupByLibrary.simpleMessage("What happened"),
    "feedback_intro": MessageLookupByLibrary.simpleMessage(
      "Write what went wrong. The report goes to Sentry with the app\'s version and the device\'s model and system, and with no name or email. The app masks the email addresses in it before it leaves the device; do not write other personal details, such as a phone number.",
    ),
    "feedback_send": MessageLookupByLibrary.simpleMessage("Send"),
    "feedback_sending": MessageLookupByLibrary.simpleMessage("Sending"),
    "feedback_sent": MessageLookupByLibrary.simpleMessage("The report is sent."),
    "feedback_title": MessageLookupByLibrary.simpleMessage("Report a problem"),
    "glossary_find": MessageLookupByLibrary.simpleMessage("Find a term"),
    "glossary_find_clear": MessageLookupByLibrary.simpleMessage("Clear the search"),
    "glossary_in": MessageLookupByLibrary.simpleMessage("In these modules"),
    "glossary_none": MessageLookupByLibrary.simpleMessage("No term matches."),
    "guide_complete": MessageLookupByLibrary.simpleMessage(
      "At the end of a module, mark it complete. The catalog shows what you have read, and Home shows what comes next.",
    ),
    "guide_complete_title": MessageLookupByLibrary.simpleMessage("Mark what you finish"),
    "guide_levels": m28,
    "guide_levels_title": MessageLookupByLibrary.simpleMessage("Level by level"),
    "guide_modules": MessageLookupByLibrary.simpleMessage(
      "Each module reads in one sitting, with diagrams and code. Some end with a few questions to check yourself.",
    ),
    "guide_modules_title": MessageLookupByLibrary.simpleMessage("Short modules"),
    "guide_offline": MessageLookupByLibrary.simpleMessage(
      "The whole course is in the app and reads without a connection. There is no account: your progress stays on this device.",
    ),
    "guide_offline_title": MessageLookupByLibrary.simpleMessage("On this device, offline"),
    "guide_replay_tour": MessageLookupByLibrary.simpleMessage("Take the tour again"),
    "guide_title": MessageLookupByLibrary.simpleMessage("How the Bazaar works"),
    "home_after": MessageLookupByLibrary.simpleMessage("Later on"),
    "home_all_complete": MessageLookupByLibrary.simpleMessage("Every written module is complete."),
    "home_continue_reading": MessageLookupByLibrary.simpleMessage("Continue reading"),
    "home_daily_another": MessageLookupByLibrary.simpleMessage("Show another"),
    "home_daily_completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "home_path": MessageLookupByLibrary.simpleMessage("Your path"),
    "home_quiz_waiting": MessageLookupByLibrary.simpleMessage("Quiz waiting"),
    "home_read_percent": m29,
    "home_record_set_aside": MessageLookupByLibrary.simpleMessage(
      "Your stored progress could not be read and was set aside. Settings says more.",
    ),
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
    "length_minutes_words": m30,
    "level_completed": m31,
    "level_completed_pending": m32,
    "level_completed_spoken": m33,
    "level_general_notes": MessageLookupByLibrary.simpleMessage("General notes"),
    "level_module_count": m34,
    "listen": MessageLookupByLibrary.simpleMessage("Listen"),
    "listen_back": MessageLookupByLibrary.simpleMessage("Previous paragraph"),
    "listen_next": MessageLookupByLibrary.simpleMessage("Next paragraph"),
    "listen_no_voice": MessageLookupByLibrary.simpleMessage(
      "This device has no voice for this language. Add one in the device\'s Settings to listen.",
    ),
    "listen_not_started": MessageLookupByLibrary.simpleMessage(
      "Listening stopped. Your place is kept; try again in a moment.",
    ),
    "listen_open": m35,
    "listen_part": m36,
    "listen_pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "listen_play": MessageLookupByLibrary.simpleMessage("Play"),
    "listen_resume": MessageLookupByLibrary.simpleMessage("Resume listening"),
    "listen_speed": m37,
    "listen_stop": MessageLookupByLibrary.simpleMessage("Stop listening"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading"),
    "module_planned": MessageLookupByLibrary.simpleMessage("Planned"),
    "nav_caravan": MessageLookupByLibrary.simpleMessage("Caravan"),
    "nav_catalog": MessageLookupByLibrary.simpleMessage("Catalog"),
    "nav_home": MessageLookupByLibrary.simpleMessage("Home"),
    "nav_practice": MessageLookupByLibrary.simpleMessage("Practice"),
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
    "pocket_lede": MessageLookupByLibrary.simpleMessage("A toy model that can talk nonsense."),
    "pocket_level": m38,
    "pocket_level_word": MessageLookupByLibrary.simpleMessage("level"),
    "pocket_loss": m39,
    "pocket_loss_empty": MessageLookupByLibrary.simpleMessage("The curve starts with the first feed."),
    "pocket_loss_title": MessageLookupByLibrary.simpleMessage("Training loss"),
    "pocket_next_module": m40,
    "pocket_read_module": MessageLookupByLibrary.simpleMessage("Read a module you finished"),
    "pocket_read_none": MessageLookupByLibrary.simpleMessage("Finish a module, and it can read it too."),
    "pocket_read_waiting": m41,
    "pocket_reset": MessageLookupByLibrary.simpleMessage("Start over"),
    "pocket_reset_body": MessageLookupByLibrary.simpleMessage(
      "It forgets every token it read and starts again at level 0. The course and its progress stay as they are.",
    ),
    "pocket_reset_keep": MessageLookupByLibrary.simpleMessage("Keep it"),
    "pocket_reset_title": MessageLookupByLibrary.simpleMessage("Start the apprentice over?"),
    "pocket_says": m42,
    "pocket_stage_label": m43,
    "pocket_stat_modules": m44,
    "pocket_stat_tokens": m45,
    "pocket_stat_words": m46,
    "pocket_stats_title": MessageLookupByLibrary.simpleMessage("What it learnt"),
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
    "pocket_status_unreadable": MessageLookupByLibrary.simpleMessage(
      "It could not read the module this time. Try again later.",
    ),
    "pocket_temperature": MessageLookupByLibrary.simpleMessage("Temperature"),
    "pocket_title": MessageLookupByLibrary.simpleMessage("Apprentice"),
    "pocket_to_next": m47,
    "practice_brief": MessageLookupByLibrary.simpleMessage("Recap"),
    "practice_brief_count": m48,
    "practice_brief_lede": MessageLookupByLibrary.simpleMessage(
      "The Summary and the Key Terms of a module you completed, card by card.",
    ),
    "practice_endless": MessageLookupByLibrary.simpleMessage("Endless review"),
    "practice_endless_lede": MessageLookupByLibrary.simpleMessage("Practice what you\'ve read, as long as you like."),
    "practice_glossary": MessageLookupByLibrary.simpleMessage("Glossary"),
    "practice_glossary_count": m49,
    "practice_latest": m50,
    "practice_quizzes": MessageLookupByLibrary.simpleMessage("Quizzes by level"),
    "practice_start": MessageLookupByLibrary.simpleMessage("Start"),
    "practice_today": MessageLookupByLibrary.simpleMessage("Today\'s review"),
    "practice_today_cards": m51,
    "practice_today_done": MessageLookupByLibrary.simpleMessage("That is all for today"),
    "practice_today_done_lede": MessageLookupByLibrary.simpleMessage("The next cards come tomorrow."),
    "practice_today_none": MessageLookupByLibrary.simpleMessage("Nothing to review today"),
    "practice_today_none_lede": MessageLookupByLibrary.simpleMessage(
      "The questions of the modules you complete come here, a few each day.",
    ),
    "practice_wrong": MessageLookupByLibrary.simpleMessage("Wrong answers"),
    "practice_wrong_all": MessageLookupByLibrary.simpleMessage("Answer them all"),
    "practice_wrong_count": m52,
    "practice_wrong_none": MessageLookupByLibrary.simpleMessage("No wrong answers now."),
    "privacy_contact": MessageLookupByLibrary.simpleMessage(
      "For any question about personal data, write to the address below.",
    ),
    "privacy_crash": MessageLookupByLibrary.simpleMessage(
      "When the app crashes, it sends a crash report to Sentry so the fault can be fixed. To follow the app\'s health by version, it also tells Sentry when it opens and closes, how long it took to open and when it froze, with a random number for this installation. None of this holds your name, what you read or your quiz answers. The app masks email addresses, passwords and tokens before they leave the device, and Sentry keeps no IP address. A problem you send under Report a problem goes to Sentry the same way.",
    ),
    "privacy_download": MessageLookupByLibrary.simpleMessage(
      "The app downloads the course from the website, which is hosted on GitHub Pages. GitHub logs and stores the IP address of every visitor for security. This record is GitHub\'s; the app keeps none.",
    ),
    "privacy_feedback_form": MessageLookupByLibrary.simpleMessage(
      "Feedback in Settings opens an anonymous Google form in your browser, and the app sends nothing to it.",
    ),
    "privacy_github_pages": MessageLookupByLibrary.simpleMessage("What is GitHub Pages?"),
    "privacy_github_statement": MessageLookupByLibrary.simpleMessage("GitHub General Privacy Statement"),
    "privacy_listen": MessageLookupByLibrary.simpleMessage(
      "Listen reads a module aloud with the device\'s own voice, and the app sends nothing for it. When the device has no voice installed for the module\'s language, its speech engine may use an online voice from the engine\'s maker.",
    ),
    "privacy_no_data": MessageLookupByLibrary.simpleMessage(
      "This app has no account, no ads and no tracking. What it sends, and where, is below; none of it is linked to you.",
    ),
    "privacy_on_device": MessageLookupByLibrary.simpleMessage(
      "Your progress, your quiz scores and your settings are saved on this device, and in the device\'s own backup when it is on; the app sends them nowhere else. Under Your progress in Settings you can back up and restore your progress, and reset your progress and quiz scores.",
    ),
    "privacy_scanner_android": MessageLookupByLibrary.simpleMessage(
      "Scan the code uses Google\'s code scanner from Google Play services. Google receives the device\'s model and system, the app\'s version, a random number for this installation and how the scan went, as its own record.",
    ),
    "privacy_scanner_ios": MessageLookupByLibrary.simpleMessage(
      "Scan the code reads the code in the app itself, and nothing leaves the device.",
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
      "Save a copy now, and restore it after updating the app. The stored record is kept on this device unchanged.",
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
    "quiz_list_count": m53,
    "quiz_list_taken": m54,
    "quiz_next": MessageLookupByLibrary.simpleMessage("Next"),
    "quiz_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quiz_progress": m55,
    "quiz_recap_correct": MessageLookupByLibrary.simpleMessage(", correct"),
    "quiz_recap_wrong": MessageLookupByLibrary.simpleMessage(", not correct"),
    "quiz_score_before": m56,
    "quiz_score_count": m57,
    "quiz_score_rest": MessageLookupByLibrary.simpleMessage("answered correctly"),
    "quiz_see_results": MessageLookupByLibrary.simpleMessage("See results"),
    "quiz_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "quiz_start_over_body": MessageLookupByLibrary.simpleMessage("The answers given so far are cleared."),
    "quiz_start_over_keep": MessageLookupByLibrary.simpleMessage("Keep going"),
    "quiz_start_over_title": MessageLookupByLibrary.simpleMessage("Start the quiz over?"),
    "quiz_subtitle": m58,
    "quiz_title": MessageLookupByLibrary.simpleMessage("Questions on this module"),
    "quiz_unavailable": MessageLookupByLibrary.simpleMessage(
      "This quiz could not be opened. Close it and try again later.",
    ),
    "quiz_wrong": m59,
    "reader_auto_completed": MessageLookupByLibrary.simpleMessage("Marked as completed"),
    "reader_band_partly_written": MessageLookupByLibrary.simpleMessage("Partly written"),
    "reader_band_parts_only": MessageLookupByLibrary.simpleMessage("Schedule of parts only"),
    "reader_before_you_start": MessageLookupByLibrary.simpleMessage("Before you start"),
    "reader_close": MessageLookupByLibrary.simpleMessage("Close"),
    "reader_completed_on": m60,
    "reader_completion_region": MessageLookupByLibrary.simpleMessage("Module completion"),
    "reader_contents": MessageLookupByLibrary.simpleMessage("Contents"),
    "reader_end_of_course": MessageLookupByLibrary.simpleMessage("End of the course"),
    "reader_failed": MessageLookupByLibrary.simpleMessage(
      "This module could not be read on this device. Try again, or restart the app.",
    ),
    "reader_find_close": MessageLookupByLibrary.simpleMessage("Stop marking the search"),
    "reader_find_next": MessageLookupByLibrary.simpleMessage("Next match"),
    "reader_find_position": m61,
    "reader_find_previous": MessageLookupByLibrary.simpleMessage("Previous match"),
    "reader_mark_complete": MessageLookupByLibrary.simpleMessage("Mark this module as complete"),
    "reader_minutes": m62,
    "reader_module_of": m63,
    "reader_next": MessageLookupByLibrary.simpleMessage("Next"),
    "reader_not_written": MessageLookupByLibrary.simpleMessage("The For Everyone version of this module is planned."),
    "reader_objectives": MessageLookupByLibrary.simpleMessage("What you will be able to do"),
    "reader_on_this_page": MessageLookupByLibrary.simpleMessage("On this page"),
    "reader_pager_planned": m64,
    "reader_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "reader_read_for_engineers": MessageLookupByLibrary.simpleMessage("Read it For Engineers"),
    "reader_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "reader_revision": m65,
    "reader_schedule_description": MessageLookupByLibrary.simpleMessage("Description"),
    "reader_schedule_item": MessageLookupByLibrary.simpleMessage("Item"),
    "reader_schedule_of_parts": MessageLookupByLibrary.simpleMessage("Schedule of parts"),
    "reader_sections": MessageLookupByLibrary.simpleMessage("Sections"),
    "reader_see_everyone": MessageLookupByLibrary.simpleMessage("See what is written For Everyone"),
    "reader_share": MessageLookupByLibrary.simpleMessage("Share this module"),
    "reader_start_of_course": MessageLookupByLibrary.simpleMessage("Start of the course"),
    "reading_note": MessageLookupByLibrary.simpleMessage("These settings change a module\'s text, not the menus."),
    "reading_preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "reading_preview_text": MessageLookupByLibrary.simpleMessage(
      "An embedding is a list of numbers that describes a piece of text. Similar meanings give similar numbers, so the pieces closest to a question can be found.",
    ),
    "reading_reset": MessageLookupByLibrary.simpleMessage("Back to the default"),
    "reading_sample_mark": MessageLookupByLibrary.simpleMessage("Aa"),
    "reading_size": MessageLookupByLibrary.simpleMessage("Text size"),
    "reading_size_large": MessageLookupByLibrary.simpleMessage("Large"),
    "reading_size_larger": MessageLookupByLibrary.simpleMessage("Larger"),
    "reading_size_largest": MessageLookupByLibrary.simpleMessage("Largest"),
    "reading_size_small": MessageLookupByLibrary.simpleMessage("Small"),
    "reading_size_standard": MessageLookupByLibrary.simpleMessage("Standard"),
    "reading_spacing": MessageLookupByLibrary.simpleMessage("Line spacing"),
    "reading_spacing_comfortable": MessageLookupByLibrary.simpleMessage("Comfortable"),
    "reading_spacing_tight": MessageLookupByLibrary.simpleMessage("Tight"),
    "reading_spacing_wide": MessageLookupByLibrary.simpleMessage("Wide"),
    "record_not_read": MessageLookupByLibrary.simpleMessage(
      "The progress stored on this device could not be read, and nothing is written over it. Tap to read it again.",
    ),
    "record_not_saved": m66,
    "record_not_saved_blocked": MessageLookupByLibrary.simpleMessage("the app could not write its file"),
    "record_not_saved_quota": MessageLookupByLibrary.simpleMessage("this device has no space left"),
    "record_not_saved_too_large": MessageLookupByLibrary.simpleMessage("the record is larger than the app will write"),
    "restore_confirm_effect": MessageLookupByLibrary.simpleMessage(
      "Restoring replaces it with the progress in the file.",
    ),
    "restore_confirm_holds": MessageLookupByLibrary.simpleMessage("On this device now:"),
    "restore_confirm_replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "restore_confirm_title": MessageLookupByLibrary.simpleMessage("Replace the progress on this device?"),
    "review_back": MessageLookupByLibrary.simpleMessage("Back to Practice"),
    "review_back_home": MessageLookupByLibrary.simpleMessage("Back to Home"),
    "review_empty": MessageLookupByLibrary.simpleMessage("No cards to show."),
    "review_finish": MessageLookupByLibrary.simpleMessage("Finish"),
    "review_progress": m67,
    "review_result": m68,
    "review_section_link": m69,
    "review_term": MessageLookupByLibrary.simpleMessage("Term"),
    "review_term_ask": MessageLookupByLibrary.simpleMessage("Which term is this?"),
    "settings_about": MessageLookupByLibrary.simpleMessage("About"),
    "settings_app_icon": MessageLookupByLibrary.simpleMessage("App icon"),
    "settings_appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "settings_check_for_updates": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "settings_content": MessageLookupByLibrary.simpleMessage("Content"),
    "settings_content_version": MessageLookupByLibrary.simpleMessage("Version"),
    "settings_customize": MessageLookupByLibrary.simpleMessage("Customize"),
    "settings_data": MessageLookupByLibrary.simpleMessage("Your progress"),
    "settings_dev_console": MessageLookupByLibrary.simpleMessage("Developer console"),
    "settings_feedback_form": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settings_feedback_form_hint": MessageLookupByLibrary.simpleMessage("An anonymous form, opened in the browser"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Language"),
    "settings_licences": MessageLookupByLibrary.simpleMessage("Licences"),
    "settings_off": MessageLookupByLibrary.simpleMessage("Off"),
    "settings_on": MessageLookupByLibrary.simpleMessage("On"),
    "settings_on_device": MessageLookupByLibrary.simpleMessage(
      "The course is on this device and reads without a connection.",
    ),
    "settings_pocket_button": MessageLookupByLibrary.simpleMessage("Apprentice"),
    "settings_privacy_legal": MessageLookupByLibrary.simpleMessage("Privacy and legal"),
    "settings_published": MessageLookupByLibrary.simpleMessage("Published"),
    "settings_reading": MessageLookupByLibrary.simpleMessage("Reading"),
    "settings_reading_style": MessageLookupByLibrary.simpleMessage("Reading settings"),
    "settings_refresh_checking": MessageLookupByLibrary.simpleMessage("Checking for updates"),
    "settings_refresh_every_start": MessageLookupByLibrary.simpleMessage(
      "At every start the app asks the site for a newer version.",
    ),
    "settings_refresh_failed": m70,
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
    "settings_website": MessageLookupByLibrary.simpleMessage("Transfer"),
    "tour_band": MessageLookupByLibrary.simpleMessage("The module to read now is always here."),
    "tour_caravan_stage": MessageLookupByLibrary.simpleMessage("The Caravan travels through the trends of AI."),
    "tour_caravan_strip": MessageLookupByLibrary.simpleMessage("Slide here, or tap a stop, to move along."),
    "tour_catalog_levels": MessageLookupByLibrary.simpleMessage(
      "Tap a level to see its modules. The ones you complete are marked.",
    ),
    "tour_catalog_search": MessageLookupByLibrary.simpleMessage("Search any topic here."),
    "tour_done": MessageLookupByLibrary.simpleMessage("Got it"),
    "tour_hello": MessageLookupByLibrary.simpleMessage("Hi, I\'m the Apprentice. Shall I show you around?"),
    "tour_home_head": MessageLookupByLibrary.simpleMessage(
      "I bring you a section every day. Tap it to read, or swipe for another.",
    ),
    "tour_home_practice": MessageLookupByLibrary.simpleMessage("A few questions and terms a day, and the glossary."),
    "tour_later": MessageLookupByLibrary.simpleMessage("Later"),
    "tour_next": MessageLookupByLibrary.simpleMessage("Next"),
    "tour_practice_today": MessageLookupByLibrary.simpleMessage("Practice here for as long as you like."),
    "tour_quiz_level": MessageLookupByLibrary.simpleMessage("Each level\'s quizzes. Take them as often as you like."),
    "tour_settings_customize": MessageLookupByLibrary.simpleMessage(
      "My wardrobe: dress me up, or change the app icon.",
    ),
    "tour_settings_guide": MessageLookupByLibrary.simpleMessage("This tour waits in How the Bazaar works."),
    "tour_settings_reading": MessageLookupByLibrary.simpleMessage("Audience, language, appearance and text size."),
    "tour_settings_website": MessageLookupByLibrary.simpleMessage(
      "Bring your progress from the website here, or send it there.",
    ),
    "tour_show_me": MessageLookupByLibrary.simpleMessage("Show me around"),
    "tour_skip": MessageLookupByLibrary.simpleMessage("Skip the tour"),
    "tour_step": m71,
    "tour_tabs": MessageLookupByLibrary.simpleMessage("Open a tab and I\'ll show you around it."),
    "track_engineers": MessageLookupByLibrary.simpleMessage("For Engineers"),
    "track_everyone": MessageLookupByLibrary.simpleMessage("For Everyone"),
    "transfer_add": MessageLookupByLibrary.simpleMessage("Add to this device\'s progress"),
    "transfer_added": MessageLookupByLibrary.simpleMessage("Added. Nothing on this device was removed."),
    "transfer_completed": m72,
    "transfer_empty": MessageLookupByLibrary.simpleMessage("This link carries no progress."),
    "transfer_keeps": MessageLookupByLibrary.simpleMessage(
      "Adding it keeps everything on this device: nothing here is removed.",
    ),
    "transfer_not_added": MessageLookupByLibrary.simpleMessage(
      "Not added. Nothing on this device changed; Add tries again.",
    ),
    "transfer_nothing_new": MessageLookupByLibrary.simpleMessage("Nothing new: this device already has all of it."),
    "transfer_ticked": m73,
    "transfer_title": MessageLookupByLibrary.simpleMessage("Progress from a link"),
    "transfer_too_large": MessageLookupByLibrary.simpleMessage(
      "Not added: with it, the progress on this device would be larger than the app can keep. Nothing was changed.",
    ),
    "transfer_unreadable": MessageLookupByLibrary.simpleMessage(
      "This link cannot be read. Make a new one on the website\'s Progress page.",
    ),
    "wardrobe_body": MessageLookupByLibrary.simpleMessage("Body"),
    "wardrobe_hat": MessageLookupByLibrary.simpleMessage("Hat"),
    "wardrobe_head": MessageLookupByLibrary.simpleMessage("Head"),
    "wardrobe_item_locked": m74,
    "wardrobe_item_worn": m75,
    "wardrobe_note": MessageLookupByLibrary.simpleMessage(
      "Each level of the apprentice unlocks something new to wear.",
    ),
    "wardrobe_preview": m76,
    "website_from_text": MessageLookupByLibrary.simpleMessage(
      "On the website, open Progress at the top and choose Move to the app. Scan the code it shows with this device.",
    ),
    "website_from_title": MessageLookupByLibrary.simpleMessage("From the website to this device"),
    "website_scan": MessageLookupByLibrary.simpleMessage("Scan the code"),
    "website_scan_denied": MessageLookupByLibrary.simpleMessage(
      "The app may not use the camera. Allow it in the device\'s Settings, or scan the code with the Camera app.",
    ),
    "website_scan_failed": MessageLookupByLibrary.simpleMessage(
      "The camera did not open. Scan the code with the Camera app instead.",
    ),
    "website_scan_not_a_link": MessageLookupByLibrary.simpleMessage(
      "That code is not a progress link from the website.",
    ),
    "website_scan_opening": MessageLookupByLibrary.simpleMessage(
      "Opening the scanner. The first time, this can take a minute.",
    ),
    "website_scan_title": MessageLookupByLibrary.simpleMessage("Scan the website\'s code"),
    "website_to_text": MessageLookupByLibrary.simpleMessage(
      "Send your progress as a link, then open the link on the computer.",
    ),
    "website_to_title": MessageLookupByLibrary.simpleMessage("From this device to the website"),
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
