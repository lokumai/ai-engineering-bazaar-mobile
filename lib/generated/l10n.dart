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
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Could not open {url}`
  String error_link_open_failed(String url) {
    return Intl.message('Could not open $url', name: 'error_link_open_failed', desc: '', args: [url]);
  }

  /// `No such module`
  String get not_found_title {
    return Intl.message('No such module', name: 'not_found_title', desc: '', args: []);
  }

  /// `This address is not a module in the curriculum. The catalog lists every one that is.`
  String get not_found_message {
    return Intl.message(
      'This address is not a module in the curriculum. The catalog lists every one that is.',
      name: 'not_found_message',
      desc: '',
      args: [],
    );
  }

  /// `AI Engineering Bazaar`
  String get app_title {
    return Intl.message('AI Engineering Bazaar', name: 'app_title', desc: '', args: []);
  }

  /// `Home`
  String get nav_home {
    return Intl.message('Home', name: 'nav_home', desc: '', args: []);
  }

  /// `Catalog`
  String get nav_catalog {
    return Intl.message('Catalog', name: 'nav_catalog', desc: '', args: []);
  }

  /// `Quiz`
  String get nav_quiz {
    return Intl.message('Quiz', name: 'nav_quiz', desc: '', args: []);
  }

  /// `Settings`
  String get nav_settings {
    return Intl.message('Settings', name: 'nav_settings', desc: '', args: []);
  }

  /// `How would you like to read?`
  String get welcome_track_title {
    return Intl.message('How would you like to read?', name: 'welcome_track_title', desc: '', args: []);
  }

  /// `Choose your language and one of the two versions of every module. You can change both any time in Settings.`
  String get welcome_track_lede {
    return Intl.message(
      'Choose your language and one of the two versions of every module. You can change both any time in Settings.',
      name: 'welcome_track_lede',
      desc: '',
      args: [],
    );
  }

  /// `The technical modules: how each part works, with the code and the numbers behind it.`
  String get welcome_track_engineers {
    return Intl.message(
      'The technical modules: how each part works, with the code and the numbers behind it.',
      name: 'welcome_track_engineers',
      desc: 'The web\'s line for the For Engineers track, src/app/page.tsx.',
      args: [],
    );
  }

  /// `The same modules in plain words, for readers with no technical background.`
  String get welcome_track_everyone {
    return Intl.message(
      'The same modules in plain words, for readers with no technical background.',
      name: 'welcome_track_everyone',
      desc: 'The web\'s line for the For Everyone track, src/app/page.tsx.',
      args: [],
    );
  }

  /// `Start reading`
  String get welcome_start {
    return Intl.message('Start reading', name: 'welcome_start', desc: '', args: []);
  }

  /// `Up next`
  String get home_up_next {
    return Intl.message('Up next', name: 'home_up_next', desc: '', args: []);
  }

  /// `Open the module`
  String get home_open_module {
    return Intl.message('Open the module', name: 'home_open_module', desc: '', args: []);
  }

  /// `Every written module is complete.`
  String get home_all_complete {
    return Intl.message('Every written module is complete.', name: 'home_all_complete', desc: '', args: []);
  }

  /// `After that`
  String get home_after {
    return Intl.message('After that', name: 'home_after', desc: '', args: []);
  }

  /// `See the whole catalog`
  String get home_see_catalog {
    return Intl.message('See the whole catalog', name: 'home_see_catalog', desc: '', args: []);
  }

  /// `Practise again`
  String get home_practice {
    return Intl.message('Practise again', name: 'home_practice', desc: '', args: []);
  }

  /// `The quizzes of the modules you completed, the ones not taken yet or with the lowest score first.`
  String get home_practice_lede {
    return Intl.message(
      'The quizzes of the modules you completed, the ones not taken yet or with the lowest score first.',
      name: 'home_practice_lede',
      desc: '',
      args: [],
    );
  }

  /// `The course is on this device`
  String get home_offline_title {
    return Intl.message('The course is on this device', name: 'home_offline_title', desc: '', args: []);
  }

  /// `It reads without a connection. At every start the app asks the site for a newer version.`
  String get home_offline_body {
    return Intl.message(
      'It reads without a connection. At every start the app asks the site for a newer version.',
      name: 'home_offline_body',
      desc: '',
      args: [],
    );
  }

  /// `Open on the web`
  String get open_on_the_web {
    return Intl.message('Open on the web', name: 'open_on_the_web', desc: '', args: []);
  }

  /// `The course cannot be opened`
  String get content_broken_title {
    return Intl.message('The course cannot be opened', name: 'content_broken_title', desc: '', args: []);
  }

  /// `The course content in this app could not be opened. An update of the app restores it. Your progress on this device is kept.`
  String get content_broken_message {
    return Intl.message(
      'The course content in this app could not be opened. An update of the app restores it. Your progress on this device is kept.',
      name: 'content_broken_message',
      desc: '',
      args: [],
    );
  }

  /// `The app could not use its storage for the course content. Your progress on this device is kept.`
  String get content_broken_storage_message {
    return Intl.message(
      'The app could not use its storage for the course content. Your progress on this device is kept.',
      name: 'content_broken_storage_message',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get loading {
    return Intl.message('Loading', name: 'loading', desc: '', args: []);
  }

  /// `Completed`
  String get catalog_filter_completed {
    return Intl.message('Completed', name: 'catalog_filter_completed', desc: '', args: []);
  }

  /// `Planned`
  String get module_planned {
    return Intl.message('Planned', name: 'module_planned', desc: '', args: []);
  }

  /// `{count, plural, =1{1 module} other{{count} modules}}`
  String level_module_count(int count) {
    return Intl.plural(
      count,
      one: '1 module',
      other: '$count modules',
      name: 'level_module_count',
      desc: '',
      args: [count],
    );
  }

  /// `~{minutes} min`
  String duration_minutes(int minutes) {
    return Intl.message('~$minutes min', name: 'duration_minutes', desc: '', args: [minutes]);
  }

  /// `~{hours} h`
  String duration_hours(int hours) {
    return Intl.message('~$hours h', name: 'duration_hours', desc: '', args: [hours]);
  }

  /// `~{hours} h {minutes} min`
  String duration_hours_minutes(int hours, int minutes) {
    return Intl.message('~$hours h $minutes min', name: 'duration_hours_minutes', desc: '', args: [hours, minutes]);
  }

  /// `{approved}/{total} completed`
  String level_completed(int approved, int total) {
    return Intl.message('$approved/$total completed', name: 'level_completed', desc: '', args: [approved, total]);
  }

  /// `--/{total} completed`
  String level_completed_pending(int total) {
    return Intl.message('--/$total completed', name: 'level_completed_pending', desc: '', args: [total]);
  }

  /// `General notes`
  String get level_general_notes {
    return Intl.message('General notes', name: 'level_general_notes', desc: '', args: []);
  }

  /// `Description`
  String get card_description {
    return Intl.message('Description', name: 'card_description', desc: '', args: []);
  }

  /// `Length`
  String get card_length {
    return Intl.message('Length', name: 'card_length', desc: '', args: []);
  }

  /// `{minutes} min`
  String card_length_minutes(int minutes) {
    return Intl.message('$minutes min', name: 'card_length_minutes', desc: '', args: [minutes]);
  }

  /// `Requires`
  String get card_requires {
    return Intl.message('Requires', name: 'card_requires', desc: '', args: []);
  }

  /// `Nothing`
  String get card_requires_nothing {
    return Intl.message('Nothing', name: 'card_requires_nothing', desc: '', args: []);
  }

  /// `This part of the course could not be read on this device. Restart the app to reload it.`
  String get content_unreadable {
    return Intl.message(
      'This part of the course could not be read on this device. Restart the app to reload it.',
      name: 'content_unreadable',
      desc: '',
      args: [],
    );
  }

  /// `FIG. {number}`
  String block_figure_caption(String number) {
    return Intl.message('FIG. $number', name: 'block_figure_caption', desc: '', args: [number]);
  }

  /// `TBL. {number}`
  String block_table_caption(String number) {
    return Intl.message('TBL. $number', name: 'block_table_caption', desc: '', args: [number]);
  }

  /// `This part needs a newer version of the app.`
  String get block_unknown {
    return Intl.message('This part needs a newer version of the app.', name: 'block_unknown', desc: '', args: []);
  }

  /// `{language} code`
  String block_code_label(String language) {
    return Intl.message('$language code', name: 'block_code_label', desc: '', args: [language]);
  }

  /// `Program output`
  String get block_program_output {
    return Intl.message('Program output', name: 'block_program_output', desc: '', args: []);
  }

  /// `Table {number}`
  String block_table_region(String number) {
    return Intl.message('Table $number', name: 'block_table_region', desc: '', args: [number]);
  }

  /// `Contents`
  String get reader_contents {
    return Intl.message('Contents', name: 'reader_contents', desc: '', args: []);
  }

  /// `Close`
  String get reader_close {
    return Intl.message('Close', name: 'reader_close', desc: '', args: []);
  }

  /// `On this page`
  String get reader_on_this_page {
    return Intl.message('On this page', name: 'reader_on_this_page', desc: '', args: []);
  }

  /// `Sections`
  String get reader_sections {
    return Intl.message('Sections', name: 'reader_sections', desc: '', args: []);
  }

  /// `Schedule of parts only`
  String get reader_band_parts_only {
    return Intl.message('Schedule of parts only', name: 'reader_band_parts_only', desc: '', args: []);
  }

  /// `Partly written`
  String get reader_band_partly_written {
    return Intl.message('Partly written', name: 'reader_band_partly_written', desc: '', args: []);
  }

  /// `{minutes} min`
  String reader_minutes(int minutes) {
    return Intl.message('$minutes min', name: 'reader_minutes', desc: '', args: [minutes]);
  }

  /// `Before you start`
  String get reader_before_you_start {
    return Intl.message('Before you start', name: 'reader_before_you_start', desc: '', args: []);
  }

  /// `What you will be able to do`
  String get reader_objectives {
    return Intl.message('What you will be able to do', name: 'reader_objectives', desc: '', args: []);
  }

  /// `Schedule of parts`
  String get reader_schedule_of_parts {
    return Intl.message('Schedule of parts', name: 'reader_schedule_of_parts', desc: '', args: []);
  }

  /// `Item`
  String get reader_schedule_item {
    return Intl.message('Item', name: 'reader_schedule_item', desc: '', args: []);
  }

  /// `Description`
  String get reader_schedule_description {
    return Intl.message('Description', name: 'reader_schedule_description', desc: '', args: []);
  }

  /// `Module completion`
  String get reader_completion_region {
    return Intl.message('Module completion', name: 'reader_completion_region', desc: '', args: []);
  }

  /// `Mark this module as complete`
  String get reader_mark_complete {
    return Intl.message('Mark this module as complete', name: 'reader_mark_complete', desc: '', args: []);
  }

  /// `Completed {date}`
  String reader_completed_on(String date) {
    return Intl.message('Completed $date', name: 'reader_completed_on', desc: '', args: [date]);
  }

  /// `Previous`
  String get reader_previous {
    return Intl.message('Previous', name: 'reader_previous', desc: '', args: []);
  }

  /// `Next`
  String get reader_next {
    return Intl.message('Next', name: 'reader_next', desc: '', args: []);
  }

  /// `{label} · Planned`
  String reader_pager_planned(String label) {
    return Intl.message('$label · Planned', name: 'reader_pager_planned', desc: '', args: [label]);
  }

  /// `Start of the course`
  String get reader_start_of_course {
    return Intl.message('Start of the course', name: 'reader_start_of_course', desc: '', args: []);
  }

  /// `End of the course`
  String get reader_end_of_course {
    return Intl.message('End of the course', name: 'reader_end_of_course', desc: '', args: []);
  }

  /// `MODULE {number} OF {count}`
  String reader_module_of(int number, int count) {
    return Intl.message('MODULE $number OF $count', name: 'reader_module_of', desc: '', args: [number, count]);
  }

  /// `Rev {hash} · {date}`
  String reader_revision(String hash, String date) {
    return Intl.message('Rev $hash · $date', name: 'reader_revision', desc: '', args: [hash, date]);
  }

  /// `The For Everyone version of this module is planned.`
  String get reader_not_written {
    return Intl.message(
      'The For Everyone version of this module is planned.',
      name: 'reader_not_written',
      desc: '',
      args: [],
    );
  }

  /// `Read it For Engineers`
  String get reader_read_for_engineers {
    return Intl.message('Read it For Engineers', name: 'reader_read_for_engineers', desc: '', args: []);
  }

  /// `See what is written For Everyone`
  String get reader_see_everyone {
    return Intl.message('See what is written For Everyone', name: 'reader_see_everyone', desc: '', args: []);
  }

  /// `Not saved: {reason}. Back up to a file to keep it.`
  String record_not_saved(String reason) {
    return Intl.message(
      'Not saved: $reason. Back up to a file to keep it.',
      name: 'record_not_saved',
      desc: '',
      args: [reason],
    );
  }

  /// `this device has no space left`
  String get record_not_saved_quota {
    return Intl.message('this device has no space left', name: 'record_not_saved_quota', desc: '', args: []);
  }

  /// `the app could not write its file`
  String get record_not_saved_blocked {
    return Intl.message('the app could not write its file', name: 'record_not_saved_blocked', desc: '', args: []);
  }

  /// `the record is larger than the app will write`
  String get record_not_saved_too_large {
    return Intl.message(
      'the record is larger than the app will write',
      name: 'record_not_saved_too_large',
      desc: '',
      args: [],
    );
  }

  /// `Questions on this module`
  String get quiz_title {
    return Intl.message('Questions on this module', name: 'quiz_title', desc: '', args: []);
  }

  /// `{count} questions on the main points of this module`
  String quiz_subtitle(int count) {
    return Intl.message(
      '$count questions on the main points of this module',
      name: 'quiz_subtitle',
      desc: '',
      args: [count],
    );
  }

  /// `Question {index} of {count}`
  String quiz_progress(int index, int count) {
    return Intl.message('Question $index of $count', name: 'quiz_progress', desc: '', args: [index, count]);
  }

  /// `Back to the module`
  String get quiz_back_to_module {
    return Intl.message('Back to the module', name: 'quiz_back_to_module', desc: '', args: []);
  }

  /// `Start over`
  String get quiz_start_over {
    return Intl.message('Start over', name: 'quiz_start_over', desc: '', args: []);
  }

  /// `Correct.`
  String get quiz_correct {
    return Intl.message('Correct.', name: 'quiz_correct', desc: '', args: []);
  }

  /// `Not this one. The answer is {letter}.`
  String quiz_wrong(String letter) {
    return Intl.message('Not this one. The answer is $letter.', name: 'quiz_wrong', desc: '', args: [letter]);
  }

  /// `Previous`
  String get quiz_previous {
    return Intl.message('Previous', name: 'quiz_previous', desc: '', args: []);
  }

  /// `Next`
  String get quiz_next {
    return Intl.message('Next', name: 'quiz_next', desc: '', args: []);
  }

  /// `See results`
  String get quiz_see_results {
    return Intl.message('See results', name: 'quiz_see_results', desc: '', args: []);
  }

  /// `{score} of {total}`
  String quiz_score_count(int score, int total) {
    return Intl.message('$score of $total', name: 'quiz_score_count', desc: '', args: [score, total]);
  }

  /// `answered correctly`
  String get quiz_score_rest {
    return Intl.message('answered correctly', name: 'quiz_score_rest', desc: '', args: []);
  }

  /// `, correct`
  String get quiz_recap_correct {
    return Intl.message(', correct', name: 'quiz_recap_correct', desc: '', args: []);
  }

  /// `, not correct`
  String get quiz_recap_wrong {
    return Intl.message(', not correct', name: 'quiz_recap_wrong', desc: '', args: []);
  }

  /// `Back to the questions`
  String get quiz_back_to_questions {
    return Intl.message('Back to the questions', name: 'quiz_back_to_questions', desc: '', args: []);
  }

  /// `Done`
  String get quiz_done {
    return Intl.message('Done', name: 'quiz_done', desc: '', args: []);
  }

  /// `This quiz could not be opened. Close it and try again later.`
  String get quiz_unavailable {
    return Intl.message(
      'This quiz could not be opened. Close it and try again later.',
      name: 'quiz_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 quiz} other{{count} quizzes}}`
  String quiz_list_count(int count) {
    return Intl.plural(count, one: '1 quiz', other: '$count quizzes', name: 'quiz_list_count', desc: '', args: [count]);
  }

  /// `The time before: {previous} of {total}. Best: {best} of {total}.`
  String quiz_score_before(int previous, int best, int total) {
    return Intl.message(
      'The time before: $previous of $total. Best: $best of $total.',
      name: 'quiz_score_before',
      desc: '',
      args: [previous, best, total],
    );
  }

  /// `Last {last} of {total} · best {best} of {total}`
  String quiz_score_line(int last, int best, int total) {
    return Intl.message(
      'Last $last of $total · best $best of $total',
      name: 'quiz_score_line',
      desc: '',
      args: [last, best, total],
    );
  }

  /// `{taken} of {total} taken`
  String quiz_list_taken(int taken, int total) {
    return Intl.message('$taken of $total taken', name: 'quiz_list_taken', desc: '', args: [taken, total]);
  }

  /// `All answers right`
  String get quiz_all_right {
    return Intl.message('All answers right', name: 'quiz_all_right', desc: '', args: []);
  }

  /// `The questions come with the {track} modules.`
  String quiz_list_engineers_only(String track) {
    return Intl.message(
      'The questions come with the $track modules.',
      name: 'quiz_list_engineers_only',
      desc: '',
      args: [track],
    );
  }

  /// `{approved}/{total}`
  String catalog_level_dial(String approved, int total) {
    return Intl.message('$approved/$total', name: 'catalog_level_dial', desc: '', args: [approved, total]);
  }

  /// `Complete {title}`
  String catalog_complete_module(String title) {
    return Intl.message('Complete $title', name: 'catalog_complete_module', desc: '', args: [title]);
  }

  /// `Complete`
  String get catalog_state_complete {
    return Intl.message('Complete', name: 'catalog_state_complete', desc: '', args: []);
  }

  /// `Not yet`
  String get catalog_state_not_yet {
    return Intl.message('Not yet', name: 'catalog_state_not_yet', desc: '', args: []);
  }

  /// `Your progress is saved on this device only. A backup file keeps it safe if the app's data is cleared, and moves it to another device or to the website.`
  String get data_line_text {
    return Intl.message(
      'Your progress is saved on this device only. A backup file keeps it safe if the app\'s data is cleared, and moves it to another device or to the website.',
      name: 'data_line_text',
      desc: '',
      args: [],
    );
  }

  /// `Back up to a file`
  String get data_back_up {
    return Intl.message('Back up to a file', name: 'data_back_up', desc: '', args: []);
  }

  /// `Restore from a file`
  String get data_restore {
    return Intl.message('Restore from a file', name: 'data_restore', desc: '', args: []);
  }

  /// `Reset`
  String get data_reset {
    return Intl.message('Reset', name: 'data_reset', desc: '', args: []);
  }

  /// `Undo`
  String get data_undo {
    return Intl.message('Undo', name: 'data_undo', desc: '', args: []);
  }

  /// `Backed up {day}`
  String data_backed_up(String day) {
    return Intl.message('Backed up $day', name: 'data_backed_up', desc: '', args: [day]);
  }

  /// `The backup file could not be written. Nothing was marked as backed up.`
  String get data_backup_not_written {
    return Intl.message(
      'The backup file could not be written. Nothing was marked as backed up.',
      name: 'data_backup_not_written',
      desc: '',
      args: [],
    );
  }

  /// `Restored from the file.`
  String get data_restored {
    return Intl.message('Restored from the file.', name: 'data_restored', desc: '', args: []);
  }

  /// `Nothing was changed. That file holds no progress; only a backup file does.`
  String get data_restore_empty {
    return Intl.message(
      'Nothing was changed. That file holds no progress; only a backup file does.',
      name: 'data_restore_empty',
      desc: '',
      args: [],
    );
  }

  /// `That file was written by a newer version of the app or the website. Update the app, then restore it again.`
  String get data_restore_newer {
    return Intl.message(
      'That file was written by a newer version of the app or the website. Update the app, then restore it again.',
      name: 'data_restore_newer',
      desc: '',
      args: [],
    );
  }

  /// `That file is not a backup the app or the website wrote. Nothing was changed.`
  String get data_restore_malformed {
    return Intl.message(
      'That file is not a backup the app or the website wrote. Nothing was changed.',
      name: 'data_restore_malformed',
      desc: '',
      args: [],
    );
  }

  /// `That file could not be opened.`
  String get data_restore_unreadable {
    return Intl.message('That file could not be opened.', name: 'data_restore_unreadable', desc: '', args: []);
  }

  /// `{seconds, plural, =1{Reset. You can undo it for 1 second.} other{Reset. You can undo it for {seconds} seconds.}}`
  String data_reset_counting(int seconds) {
    return Intl.plural(
      seconds,
      one: 'Reset. You can undo it for 1 second.',
      other: 'Reset. You can undo it for $seconds seconds.',
      name: 'data_reset_counting',
      desc: '',
      args: [seconds],
    );
  }

  /// `Reset. The time to undo it has passed.`
  String get data_reset_closed {
    return Intl.message('Reset. The time to undo it has passed.', name: 'data_reset_closed', desc: '', args: []);
  }

  /// `The reset did not finish: the app could not delete its files. The progress on this device is unchanged.`
  String get data_reset_not_finished {
    return Intl.message(
      'The reset did not finish: the app could not delete its files. The progress on this device is unchanged.',
      name: 'data_reset_not_finished',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 module state} other{{count} module states}}`
  String data_tally_states(int count) {
    return Intl.plural(
      count,
      one: '1 module state',
      other: '$count module states',
      name: 'data_tally_states',
      desc: '',
      args: [count],
    );
  }

  /// `NOTHING RECORDED ON THIS DEVICE`
  String get data_tally_nothing {
    return Intl.message('NOTHING RECORDED ON THIS DEVICE', name: 'data_tally_nothing', desc: '', args: []);
  }

  /// `Erase`
  String get erase_mark {
    return Intl.message('Erase', name: 'erase_mark', desc: '', args: []);
  }

  /// `Erase all progress on this device?`
  String get erase_title {
    return Intl.message('Erase all progress on this device?', name: 'erase_title', desc: '', args: []);
  }

  /// `This removes the record from this device, including the copy set aside from a version of the app this one could not read.`
  String get erase_scope {
    return Intl.message(
      'This removes the record from this device, including the copy set aside from a version of the app this one could not read.',
      name: 'erase_scope',
      desc: '',
      args: [],
    );
  }

  /// `The quiz scores on this device are erased too.`
  String get erase_scores {
    return Intl.message('The quiz scores on this device are erased too.', name: 'erase_scores', desc: '', args: []);
  }

  /// `A device backup may still hold an earlier copy of your progress.`
  String get erase_backup_statement {
    return Intl.message(
      'A device backup may still hold an earlier copy of your progress.',
      name: 'erase_backup_statement',
      desc: '',
      args: [],
    );
  }

  /// `Type ERASE to confirm`
  String get erase_field_label {
    return Intl.message('Type ERASE to confirm', name: 'erase_field_label', desc: '', args: []);
  }

  /// `Erase all data`
  String get erase_confirm {
    return Intl.message('Erase all data', name: 'erase_confirm', desc: '', args: []);
  }

  /// `Keep my data`
  String get erase_keep {
    return Intl.message('Keep my data', name: 'erase_keep', desc: '', args: []);
  }

  /// `Replace the progress on this device?`
  String get restore_confirm_title {
    return Intl.message('Replace the progress on this device?', name: 'restore_confirm_title', desc: '', args: []);
  }

  /// `On this device now:`
  String get restore_confirm_holds {
    return Intl.message('On this device now:', name: 'restore_confirm_holds', desc: '', args: []);
  }

  /// `Restoring replaces it with the progress in the file.`
  String get restore_confirm_effect {
    return Intl.message(
      'Restoring replaces it with the progress in the file.',
      name: 'restore_confirm_effect',
      desc: '',
      args: [],
    );
  }

  /// `Replace`
  String get restore_confirm_replace {
    return Intl.message('Replace', name: 'restore_confirm_replace', desc: '', args: []);
  }

  /// `Record status`
  String get quarantine_label {
    return Intl.message('Record status', name: 'quarantine_label', desc: '', args: []);
  }

  /// `PROGRESS WRITTEN BY A NEWER VERSION OF THE APP. NOT READ.`
  String get quarantine_newer_readout {
    return Intl.message(
      'PROGRESS WRITTEN BY A NEWER VERSION OF THE APP. NOT READ.',
      name: 'quarantine_newer_readout',
      desc: '',
      args: [],
    );
  }

  /// `Update the app to read it. The stored record is kept on this device unchanged.`
  String get quarantine_newer_note {
    return Intl.message(
      'Update the app to read it. The stored record is kept on this device unchanged.',
      name: 'quarantine_newer_note',
      desc: '',
      args: [],
    );
  }

  /// `PROGRESS THIS VERSION OF THE APP COULD NOT READ. NOT READ.`
  String get quarantine_malformed_readout {
    return Intl.message(
      'PROGRESS THIS VERSION OF THE APP COULD NOT READ. NOT READ.',
      name: 'quarantine_malformed_readout',
      desc: '',
      args: [],
    );
  }

  /// `The stored record is not a shape this version of the app can read. It has been copied aside on this device unchanged rather than discarded, and nothing has been written over it.`
  String get quarantine_malformed_note {
    return Intl.message(
      'The stored record is not a shape this version of the app can read. It has been copied aside on this device unchanged rather than discarded, and nothing has been written over it.',
      name: 'quarantine_malformed_note',
      desc: '',
      args: [],
    );
  }

  /// `A STORED RECORD IS SET ASIDE`
  String get quarantine_kept_readout {
    return Intl.message('A STORED RECORD IS SET ASIDE', name: 'quarantine_kept_readout', desc: '', args: []);
  }

  /// `An earlier launch could not read the stored progress. Its bytes are kept on this device unchanged.`
  String get quarantine_kept_note {
    return Intl.message(
      'An earlier launch could not read the stored progress. Its bytes are kept on this device unchanged.',
      name: 'quarantine_kept_note',
      desc: '',
      args: [],
    );
  }

  /// `Save a copy`
  String get quarantine_save_copy {
    return Intl.message('Save a copy', name: 'quarantine_save_copy', desc: '', args: []);
  }

  /// `Saved a copy of the set-aside record.`
  String get quarantine_copy_saved {
    return Intl.message('Saved a copy of the set-aside record.', name: 'quarantine_copy_saved', desc: '', args: []);
  }

  /// `The copy could not be written. The set-aside record is unchanged.`
  String get quarantine_copy_not_written {
    return Intl.message(
      'The copy could not be written. The set-aside record is unchanged.',
      name: 'quarantine_copy_not_written',
      desc: '',
      args: [],
    );
  }

  /// `Delete it`
  String get quarantine_delete {
    return Intl.message('Delete it', name: 'quarantine_delete', desc: '', args: []);
  }

  /// `Delete the set-aside record?`
  String get quarantine_delete_title {
    return Intl.message('Delete the set-aside record?', name: 'quarantine_delete_title', desc: '', args: []);
  }

  /// `This version of the app cannot read it. Deleting it cannot be undone.`
  String get quarantine_delete_body {
    return Intl.message(
      'This version of the app cannot read it. Deleting it cannot be undone.',
      name: 'quarantine_delete_body',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get quarantine_delete_confirm {
    return Intl.message('Delete', name: 'quarantine_delete_confirm', desc: '', args: []);
  }

  /// `Keep it`
  String get quarantine_keep {
    return Intl.message('Keep it', name: 'quarantine_keep', desc: '', args: []);
  }

  /// `The downloaded content could not be read, so the app removed it and shows the content that came with this version. Check for updates in Settings to download it again.`
  String get content_notice_cache_discarded {
    return Intl.message(
      'The downloaded content could not be read, so the app removed it and shows the content that came with this version. Check for updates in Settings to download it again.',
      name: 'content_notice_cache_discarded',
      desc: '',
      args: [],
    );
  }

  /// `Reading`
  String get settings_reading {
    return Intl.message('Reading', name: 'settings_reading', desc: '', args: []);
  }

  /// `Audience`
  String get settings_track {
    return Intl.message('Audience', name: 'settings_track', desc: '', args: []);
  }

  /// `Your progress`
  String get settings_data {
    return Intl.message('Your progress', name: 'settings_data', desc: '', args: []);
  }

  /// `Content`
  String get settings_content {
    return Intl.message('Content', name: 'settings_content', desc: '', args: []);
  }

  /// `Version`
  String get settings_content_version {
    return Intl.message('Version', name: 'settings_content_version', desc: '', args: []);
  }

  /// `Published`
  String get settings_published {
    return Intl.message('Published', name: 'settings_published', desc: '', args: []);
  }

  /// `Source`
  String get settings_source {
    return Intl.message('Source', name: 'settings_source', desc: '', args: []);
  }

  /// `Bundled with the app`
  String get settings_source_bundled {
    return Intl.message('Bundled with the app', name: 'settings_source_bundled', desc: '', args: []);
  }

  /// `Downloaded from the website`
  String get settings_source_downloaded {
    return Intl.message('Downloaded from the website', name: 'settings_source_downloaded', desc: '', args: []);
  }

  /// `Not checked since the app started`
  String get settings_refresh_idle {
    return Intl.message('Not checked since the app started', name: 'settings_refresh_idle', desc: '', args: []);
  }

  /// `Checking for updates`
  String get settings_refresh_checking {
    return Intl.message('Checking for updates', name: 'settings_refresh_checking', desc: '', args: []);
  }

  /// `Up to date`
  String get settings_refresh_up_to_date {
    return Intl.message('Up to date', name: 'settings_refresh_up_to_date', desc: '', args: []);
  }

  /// `Updated to the latest content`
  String get settings_refresh_updated {
    return Intl.message('Updated to the latest content', name: 'settings_refresh_updated', desc: '', args: []);
  }

  /// `Newer content needs a newer version of the app. Update the app to get it.`
  String get settings_refresh_needs_app_update {
    return Intl.message(
      'Newer content needs a newer version of the app. Update the app to get it.',
      name: 'settings_refresh_needs_app_update',
      desc: '',
      args: [],
    );
  }

  /// `The check for updates did not finish: {reason}.`
  String settings_refresh_failed(String reason) {
    return Intl.message(
      'The check for updates did not finish: $reason.',
      name: 'settings_refresh_failed',
      desc: '',
      args: [reason],
    );
  }

  /// `no connection to the website`
  String get settings_refresh_reason_network {
    return Intl.message('no connection to the website', name: 'settings_refresh_reason_network', desc: '', args: []);
  }

  /// `the website answered with an error`
  String get settings_refresh_reason_http_status {
    return Intl.message(
      'the website answered with an error',
      name: 'settings_refresh_reason_http_status',
      desc: '',
      args: [],
    );
  }

  /// `the website sent content this version of the app cannot read`
  String get settings_refresh_reason_format {
    return Intl.message(
      'the website sent content this version of the app cannot read',
      name: 'settings_refresh_reason_format',
      desc: '',
      args: [],
    );
  }

  /// `a downloaded file did not match its checksum`
  String get settings_refresh_reason_checksum {
    return Intl.message(
      'a downloaded file did not match its checksum',
      name: 'settings_refresh_reason_checksum',
      desc: '',
      args: [],
    );
  }

  /// `the app could not write to its storage`
  String get settings_refresh_reason_storage {
    return Intl.message(
      'the app could not write to its storage',
      name: 'settings_refresh_reason_storage',
      desc: '',
      args: [],
    );
  }

  /// `the stored content could not be read`
  String get settings_refresh_reason_stored {
    return Intl.message(
      'the stored content could not be read',
      name: 'settings_refresh_reason_stored',
      desc: '',
      args: [],
    );
  }

  /// `Check for updates`
  String get settings_check_for_updates {
    return Intl.message('Check for updates', name: 'settings_check_for_updates', desc: '', args: []);
  }

  /// `About`
  String get settings_about {
    return Intl.message('About', name: 'settings_about', desc: '', args: []);
  }

  /// `Licences`
  String get settings_licences {
    return Intl.message('Licences', name: 'settings_licences', desc: '', args: []);
  }

  /// `Developer console`
  String get settings_dev_console {
    return Intl.message('Developer console', name: 'settings_dev_console', desc: '', args: []);
  }

  /// `Language`
  String get settings_language {
    return Intl.message(
      'Language',
      name: 'settings_language',
      desc: 'Settings\' language setting (plan 1Q).',
      args: [],
    );
  }

  /// `For Engineers`
  String get track_engineers {
    return Intl.message(
      'For Engineers',
      name: 'track_engineers',
      desc: 'The For Engineers track\'s name; the bundle names tracks in English only.',
      args: [],
    );
  }

  /// `For Everyone`
  String get track_everyone {
    return Intl.message(
      'For Everyone',
      name: 'track_everyone',
      desc: 'The For Everyone track\'s name; the bundle names tracks in English only.',
      args: [],
    );
  }

  /// `How the bazaar works`
  String get guide_title {
    return Intl.message(
      'How the bazaar works',
      name: 'guide_title',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `Level by level`
  String get guide_levels_title {
    return Intl.message(
      'Level by level',
      name: 'guide_levels_title',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `The course is set out in {count} levels, starting with {first}. Begin with the first and move on when you are ready.`
  String guide_levels(int count, String first) {
    return Intl.message(
      'The course is set out in $count levels, starting with $first. Begin with the first and move on when you are ready.',
      name: 'guide_levels',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [count, first],
    );
  }

  /// `Short modules`
  String get guide_modules_title {
    return Intl.message(
      'Short modules',
      name: 'guide_modules_title',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `Each module is a 20 to 30 minute read, with diagrams and code. Some end with a few questions to check yourself.`
  String get guide_modules {
    return Intl.message(
      'Each module is a 20 to 30 minute read, with diagrams and code. Some end with a few questions to check yourself.',
      name: 'guide_modules',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `Mark what you finish`
  String get guide_complete_title {
    return Intl.message(
      'Mark what you finish',
      name: 'guide_complete_title',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `At the end of a module, mark it complete. The catalog shows what you have read, and Home shows what comes next.`
  String get guide_complete {
    return Intl.message(
      'At the end of a module, mark it complete. The catalog shows what you have read, and Home shows what comes next.',
      name: 'guide_complete',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `On this device, offline`
  String get guide_offline_title {
    return Intl.message(
      'On this device, offline',
      name: 'guide_offline_title',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `The whole course is in the app and reads without a connection. There is no account: your progress stays on this phone.`
  String get guide_offline {
    return Intl.message(
      'The whole course is in the app and reads without a connection. There is no account: your progress stays on this phone.',
      name: 'guide_offline',
      desc: 'Welcome\'s first-launch guide (plan 1X).',
      args: [],
    );
  }

  /// `Continue`
  String get welcome_story_continue {
    return Intl.message(
      'Continue',
      name: 'welcome_story_continue',
      desc: 'Welcome\'s first step: the button after the story of the Bazaar, on to the language and the track (plan 3.5).',
      args: [],
    );
  }

  /// `Privacy and legal`
  String get settings_privacy_legal {
    return Intl.message(
      'Privacy and legal',
      name: 'settings_privacy_legal',
      desc: 'Settings\' privacy and legal page (plan 3.4, web D122).',
      args: [],
    );
  }

  /// `Privacy`
  String get privacy_title {
    return Intl.message('Privacy', name: 'privacy_title', desc: '', args: []);
  }

  /// `This app collects no personal data. It has no account, no analytics and no ads.`
  String get privacy_no_data {
    return Intl.message(
      'This app collects no personal data. It has no account, no analytics and no ads.',
      name: 'privacy_no_data',
      desc: '',
      args: [],
    );
  }

  /// `Your progress, your quiz scores and your settings are saved on this device only. You can back them up, restore or erase them under Your progress in Settings.`
  String get privacy_on_device {
    return Intl.message(
      'Your progress, your quiz scores and your settings are saved on this device only. You can back them up, restore or erase them under Your progress in Settings.',
      name: 'privacy_on_device',
      desc: '',
      args: [],
    );
  }

  /// `The app downloads the course from the website, which is hosted on GitHub Pages. GitHub logs and stores the IP address of every visitor for security. This is GitHub's record, not ours.`
  String get privacy_download {
    return Intl.message(
      'The app downloads the course from the website, which is hosted on GitHub Pages. GitHub logs and stores the IP address of every visitor for security. This is GitHub\'s record, not ours.',
      name: 'privacy_download',
      desc: '',
      args: [],
    );
  }

  /// `When the app crashes, it sends a crash report to Sentry so the fault can be fixed. The app masks personal details in the report before it leaves the device.`
  String get privacy_crash {
    return Intl.message(
      'When the app crashes, it sends a crash report to Sentry so the fault can be fixed. The app masks personal details in the report before it leaves the device.',
      name: 'privacy_crash',
      desc: '',
      args: [],
    );
  }

  /// `For any question about personal data, write to us.`
  String get privacy_contact {
    return Intl.message(
      'For any question about personal data, write to us.',
      name: 'privacy_contact',
      desc: '',
      args: [],
    );
  }

  /// `Legal`
  String get legal_title {
    return Intl.message('Legal', name: 'legal_title', desc: '', args: []);
  }

  /// `Owner`
  String get legal_owner {
    return Intl.message('Owner', name: 'legal_owner', desc: '', args: []);
  }

  /// `MERSİS no.`
  String get legal_mersis {
    return Intl.message('MERSİS no.', name: 'legal_mersis', desc: '', args: []);
  }

  /// `Address`
  String get legal_address {
    return Intl.message('Address', name: 'legal_address', desc: '', args: []);
  }

  /// `Email`
  String get legal_email {
    return Intl.message('Email', name: 'legal_email', desc: '', args: []);
  }

  /// `Phone`
  String get legal_phone {
    return Intl.message('Phone', name: 'legal_phone', desc: '', args: []);
  }

  /// `Third-party marks and images`
  String get legal_marks_title {
    return Intl.message('Third-party marks and images', name: 'legal_marks_title', desc: '', args: []);
  }

  /// `Company names and logos shown in the modules belong to their owners. They appear only to say which company is meant, and they do not mean that the company endorses this app.`
  String get legal_marks {
    return Intl.message(
      'Company names and logos shown in the modules belong to their owners. They appear only to say which company is meant, and they do not mean that the company endorses this app.',
      name: 'legal_marks',
      desc: '',
      args: [],
    );
  }

  /// `Some images come from articles and other public sources, with sincere thanks to their authors. They remain the property of their owners, no rights in them are claimed, and they are shown only to explain the point next to them. The owner of an image or a mark shown here can write to the address below to have it credited or removed, whichever they prefer.`
  String get legal_images {
    return Intl.message(
      'Some images come from articles and other public sources, with sincere thanks to their authors. They remain the property of their owners, no rights in them are claimed, and they are shown only to explain the point next to them. The owner of an image or a mark shown here can write to the address below to have it credited or removed, whichever they prefer.',
      name: 'legal_images',
      desc: '',
      args: [],
    );
  }

  /// `The project's MIT licence covers its code and its content. It does not cover third-party marks or images.`
  String get legal_licence {
    return Intl.message(
      'The project\'s MIT licence covers its code and its content. It does not cover third-party marks or images.',
      name: 'legal_licence',
      desc: '',
      args: [],
    );
  }

  /// `MIT licence`
  String get legal_licence_link {
    return Intl.message('MIT licence', name: 'legal_licence_link', desc: '', args: []);
  }

  /// `What is GitHub Pages?`
  String get privacy_github_pages {
    return Intl.message('What is GitHub Pages?', name: 'privacy_github_pages', desc: '', args: []);
  }

  /// `GitHub General Privacy Statement`
  String get privacy_github_statement {
    return Intl.message('GitHub General Privacy Statement', name: 'privacy_github_statement', desc: '', args: []);
  }

  /// `The story of the Bazaar`
  String get settings_story {
    return Intl.message(
      'The story of the Bazaar',
      name: 'settings_story',
      desc: 'Settings, About: the row that opens the story of the Bazaar (web D115, D125).',
      args: [],
    );
  }

  /// `The story could not be opened. Check for updates, then open it again.`
  String get about_failed {
    return Intl.message(
      'The story could not be opened. Check for updates, then open it again.',
      name: 'about_failed',
      desc: 'The About page, when the story document cannot be read.',
      args: [],
    );
  }

  /// `The story is written in English.`
  String get about_english {
    return Intl.message(
      'The story is written in English.',
      name: 'about_english',
      desc:
          'The About page, above the story, when the app\'s language is not English: the story has no translation yet.',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'fa'),
      Locale.fromSubtags(languageCode: 'tr'),
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
