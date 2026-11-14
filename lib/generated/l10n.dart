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

  /// `Caravan`
  String get nav_caravan {
    return Intl.message('Caravan', name: 'nav_caravan', desc: '', args: []);
  }

  /// `Sample data: these trends are placeholders while the Caravan is being built.`
  String get caravan_sample_notice {
    return Intl.message(
      'Sample data: these trends are placeholders while the Caravan is being built.',
      name: 'caravan_sample_notice',
      desc: 'The notice over the Caravan while it draws the web\'s sample trends, as the web\'s notice says (web CaravanPage.tsx).',
      args: [],
    );
  }

  /// `The caravan at {title}`
  String caravan_stage_label(String title) {
    return Intl.message(
      'The caravan at $title',
      name: 'caravan_stage_label',
      desc: 'The stage\'s name for a screen reader: the caravan at the chosen trend.',
      args: [title],
    );
  }

  /// `Stop {index} of {count}`
  String caravan_stop_of(int index, int count) {
    return Intl.message('Stop $index of $count', name: 'caravan_stop_of', desc: '', args: [index, count]);
  }

  /// `Previous stop`
  String get caravan_previous {
    return Intl.message('Previous stop', name: 'caravan_previous', desc: '', args: []);
  }

  /// `Next stop`
  String get caravan_next {
    return Intl.message('Next stop', name: 'caravan_next', desc: '', args: []);
  }

  /// `Tour the road`
  String get caravan_tour {
    return Intl.message(
      'Tour the road',
      name: 'caravan_tour',
      desc: 'The button that walks the caravan from stop to stop on its own.',
      args: [],
    );
  }

  /// `Stop the tour`
  String get caravan_tour_stop {
    return Intl.message('Stop the tour', name: 'caravan_tour_stop', desc: '', args: []);
  }

  /// `Where the caravan is`
  String get caravan_strip_label {
    return Intl.message(
      'Where the caravan is',
      name: 'caravan_strip_label',
      desc: 'The strip under the stage, a slider over the stops.',
      args: [],
    );
  }

  /// `Swipe the card, drag the road or tap a stall to travel.`
  String get caravan_hint {
    return Intl.message(
      'Swipe the card, drag the road or tap a stall to travel.',
      name: 'caravan_hint',
      desc: '',
      args: [],
    );
  }

  /// `{start} to {end}`
  String caravan_period(String start, String end) {
    return Intl.message(
      '$start to $end',
      name: 'caravan_period',
      desc: 'When a trend was on the road, its first and last month.',
      args: [start, end],
    );
  }

  /// `{start} to now`
  String caravan_period_open(String start) {
    return Intl.message(
      '$start to now',
      name: 'caravan_period_open',
      desc: 'When a trend still on the road started.',
      args: [start],
    );
  }

  /// `Strength`
  String get caravan_strength {
    return Intl.message('Strength', name: 'caravan_strength', desc: '', args: []);
  }

  /// `Strength {level} of 5`
  String caravan_strength_of(int level) {
    return Intl.message('Strength $level of 5', name: 'caravan_strength_of', desc: '', args: [level]);
  }

  /// `In the course`
  String get caravan_in_course {
    return Intl.message(
      'In the course',
      name: 'caravan_in_course',
      desc: 'The modules of the course on a trend\'s subject.',
      args: [],
    );
  }

  /// `To read`
  String get caravan_reading {
    return Intl.message('To read', name: 'caravan_reading', desc: '', args: []);
  }

  /// `Sample article`
  String get caravan_sample_articles {
    return Intl.message('Sample article', name: 'caravan_sample_articles', desc: '', args: []);
  }

  /// `Sample video`
  String get caravan_sample_videos {
    return Intl.message('Sample video', name: 'caravan_sample_videos', desc: '', args: []);
  }

  /// `Sample tool`
  String get caravan_sample_tools {
    return Intl.message('Sample tool', name: 'caravan_sample_tools', desc: '', args: []);
  }

  /// `Sample repository`
  String get caravan_sample_repositories {
    return Intl.message('Sample repository', name: 'caravan_sample_repositories', desc: '', args: []);
  }

  /// `Sample`
  String get caravan_sample_badge {
    return Intl.message('Sample', name: 'caravan_sample_badge', desc: '', args: []);
  }

  /// `All trends`
  String get caravan_all_trends {
    return Intl.message('All trends', name: 'caravan_all_trends', desc: '', args: []);
  }

  /// `Search the trends`
  String get caravan_search {
    return Intl.message('Search the trends', name: 'caravan_search', desc: '', args: []);
  }

  /// `All years`
  String get caravan_all_years {
    return Intl.message('All years', name: 'caravan_all_years', desc: '', args: []);
  }

  /// `No trend matches.`
  String get caravan_no_trend {
    return Intl.message('No trend matches.', name: 'caravan_no_trend', desc: '', args: []);
  }

  /// `{count, plural, =1{1 trend} other{{count} trends}}`
  String caravan_trend_count(int count) {
    return Intl.plural(
      count,
      one: '1 trend',
      other: '$count trends',
      name: 'caravan_trend_count',
      desc: '',
      args: [count],
    );
  }

  /// `How would you like to read?`
  String get welcome_track_title {
    return Intl.message('How would you like to read?', name: 'welcome_track_title', desc: '', args: []);
  }

  /// `The technical modules: how each part works, with the code and numbers.`
  String get welcome_track_engineers {
    return Intl.message(
      'The technical modules: how each part works, with the code and numbers.',
      name: 'welcome_track_engineers',
      desc: 'The web\'s line for the For Engineers track (src/app/page.tsx), a little shorter so it takes two lines on a phone, as the other track\'s does (the owner, 2026-11-15).',
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

  /// `Start learning`
  String get welcome_start {
    return Intl.message(
      'Start learning',
      name: 'welcome_start',
      desc: 'Welcome\'s first step: the main button, which opens the app on Home with the language and the track chosen (the owner, 2026-11-15).',
      args: [],
    );
  }

  /// `Our story`
  String get welcome_to_story {
    return Intl.message(
      'Our story',
      name: 'welcome_to_story',
      desc: 'Welcome\'s first step: the button under Start learning, to the story of the Bazaar, when there is one (plan 3.5). The owner\'s words, kept though the copy register bans the first person (the owner, 2026-11-15).',
      args: [],
    );
  }

  /// `Up next`
  String get home_up_next {
    return Intl.message('Up next', name: 'home_up_next', desc: '', args: []);
  }

  /// `Open the module`
  String get home_open_module {
    return Intl.message('Open the module', name: 'home_open_module', desc: '', args: []);
  }

  /// `Continue reading`
  String get home_continue_reading {
    return Intl.message('Continue reading', name: 'home_continue_reading', desc: '', args: []);
  }

  /// `{percent} % read`
  String home_read_percent(int percent) {
    return Intl.message(
      '$percent % read',
      name: 'home_read_percent',
      desc: 'How far down a half-read module the reader left it, on Home\'s continue card.',
      args: [percent],
    );
  }

  /// `Continue`
  String get home_continue {
    return Intl.message('Continue', name: 'home_continue', desc: '', args: []);
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

  /// `Quizzes to practise`
  String get home_practice {
    return Intl.message('Quizzes to practise', name: 'home_practice', desc: '', args: []);
  }

  /// `Quizzes from the modules you completed.`
  String get home_practice_lede {
    return Intl.message('Quizzes from the modules you completed.', name: 'home_practice_lede', desc: '', args: []);
  }

  /// `Open the diagram full screen`
  String get diagram_expand {
    return Intl.message('Open the diagram full screen', name: 'diagram_expand', desc: '', args: []);
  }

  /// `Open the image full screen`
  String get image_expand {
    return Intl.message('Open the image full screen', name: 'image_expand', desc: '', args: []);
  }

  /// `Replay`
  String get image_replay {
    return Intl.message(
      'Replay',
      name: 'image_replay',
      desc: 'The button over an animated recording that plays it again from its start (web D136).',
      args: [],
    );
  }

  /// `Your path`
  String get home_path {
    return Intl.message('Your path', name: 'home_path', desc: '', args: []);
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

  /// `Search the modules`
  String get catalog_search_hint {
    return Intl.message('Search the modules', name: 'catalog_search_hint', desc: '', args: []);
  }

  /// `Clear the search`
  String get catalog_search_clear {
    return Intl.message('Clear the search', name: 'catalog_search_clear', desc: '', args: []);
  }

  /// `{count, plural, =1{1 result} other{{count} results}}`
  String catalog_search_count(int count) {
    return Intl.plural(
      count,
      one: '1 result',
      other: '$count results',
      name: 'catalog_search_count',
      desc: '',
      args: [count],
    );
  }

  /// `the first {count} shown`
  String catalog_search_shown(int count) {
    return Intl.message('the first $count shown', name: 'catalog_search_shown', desc: '', args: [count]);
  }

  /// `Nothing found for “{query}”.`
  String catalog_search_none(String query) {
    return Intl.message('Nothing found for “$query”.', name: 'catalog_search_none', desc: '', args: [query]);
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

  /// `Previous match`
  String get reader_find_previous {
    return Intl.message('Previous match', name: 'reader_find_previous', desc: '', args: []);
  }

  /// `Next match`
  String get reader_find_next {
    return Intl.message('Next match', name: 'reader_find_next', desc: '', args: []);
  }

  /// `Stop marking the search`
  String get reader_find_close {
    return Intl.message('Stop marking the search', name: 'reader_find_close', desc: '', args: []);
  }

  /// `Match {position} of {total}`
  String reader_find_position(int position, int total) {
    return Intl.message('Match $position of $total', name: 'reader_find_position', desc: '', args: [position, total]);
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

  /// `{minutes} min · {words} words`
  String length_minutes_words(int minutes, String words) {
    return Intl.message(
      '$minutes min · $words words',
      name: 'length_minutes_words',
      desc: 'A written module\'s length, as its web page prints it under the title (web readingTime); words already grouped.',
      args: [minutes, words],
    );
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

  /// `Back up`
  String get data_back_up {
    return Intl.message('Back up', name: 'data_back_up', desc: '', args: []);
  }

  /// `Restore`
  String get data_restore {
    return Intl.message('Restore', name: 'data_restore', desc: '', args: []);
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

  /// `The file was not restored, because a reset was under way. Try again.`
  String get data_restore_not_done {
    return Intl.message(
      'The file was not restored, because a reset was under way. Try again.',
      name: 'data_restore_not_done',
      desc: '',
      args: [],
    );
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

  /// `That backup is larger than the app can keep. Nothing was changed.`
  String get data_restore_too_large {
    return Intl.message(
      'That backup is larger than the app can keep. Nothing was changed.',
      name: 'data_restore_too_large',
      desc: '',
      args: [],
    );
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

  /// `ERASE`
  String get erase_word {
    return Intl.message(
      'ERASE',
      name: 'erase_word',
      desc: 'The word the reader types to confirm a reset, in the interface\'s language; ERASE is taken in every language too.',
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

  /// `Appearance`
  String get settings_appearance {
    return Intl.message(
      'Appearance',
      name: 'settings_appearance',
      desc: 'The label of the setting that chooses the look of the app, in Settings and on Welcome\'s first step.',
      args: [],
    );
  }

  /// `Light`
  String get appearance_light {
    return Intl.message(
      'Light',
      name: 'appearance_light',
      desc: 'Appearance choice: the app is always light.',
      args: [],
    );
  }

  /// `Dark`
  String get appearance_dark {
    return Intl.message('Dark', name: 'appearance_dark', desc: 'Appearance choice: the app is always dark.', args: []);
  }

  /// `App icon`
  String get settings_app_icon {
    return Intl.message(
      'App icon',
      name: 'settings_app_icon',
      desc: 'Settings\' row that opens the page to choose the app\'s icon on the home screen, and that page\'s title.',
      args: [],
    );
  }

  /// `Dark`
  String get app_icon_dark {
    return Intl.message(
      'Dark',
      name: 'app_icon_dark',
      desc: 'App icon choice: the striped agent on the dark ground, the default.',
      args: [],
    );
  }

  /// `Cream`
  String get app_icon_cream {
    return Intl.message(
      'Cream',
      name: 'app_icon_cream',
      desc: 'App icon choice: the striped agent on a cream ground.',
      args: [],
    );
  }

  /// `Noir`
  String get app_icon_noir {
    return Intl.message(
      'Noir',
      name: 'app_icon_noir',
      desc: 'App icon choice: cream stripes on the dark ground, like a black and white film.',
      args: [],
    );
  }

  /// `Ink`
  String get app_icon_ink {
    return Intl.message(
      'Ink',
      name: 'app_icon_ink',
      desc: 'App icon choice: dark stripes on a cream ground.',
      args: [],
    );
  }

  /// `Night gold`
  String get app_icon_night_gold {
    return Intl.message(
      'Night gold',
      name: 'app_icon_night_gold',
      desc: 'App icon choice: gold stripes on the dark ground.',
      args: [],
    );
  }

  /// `Night sea`
  String get app_icon_night_sea {
    return Intl.message(
      'Night sea',
      name: 'app_icon_night_sea',
      desc: 'App icon choice: teal, gold and cream stripes on a deep green ground.',
      args: [],
    );
  }

  /// `Default`
  String get app_icon_default {
    return Intl.message(
      'Default',
      name: 'app_icon_default',
      desc: 'Under the default app icon\'s name on the app icon page.',
      args: [],
    );
  }

  /// `The new icon reaches the home screen when you leave the app. Some phones then take its shortcut off the home screen; the app list shows it in the new colours. With themed icons on, the phone draws every icon in its own colours.`
  String get app_icon_note_android {
    return Intl.message(
      'The new icon reaches the home screen when you leave the app. Some phones then take its shortcut off the home screen; the app list shows it in the new colours. With themed icons on, the phone draws every icon in its own colours.',
      name: 'app_icon_note_android',
      desc: 'The note on the app icon page on Android: when the icon changes, and what some launchers do.',
      args: [],
    );
  }

  /// `The phone confirms the new icon with a message.`
  String get app_icon_note_ios {
    return Intl.message(
      'The phone confirms the new icon with a message.',
      name: 'app_icon_note_ios',
      desc: 'The note on the app icon page on iOS, where the system tells of every icon change.',
      args: [],
    );
  }

  /// `Done`
  String get welcome_app_icon_done {
    return Intl.message(
      'Done',
      name: 'welcome_app_icon_done',
      desc: 'The button under the six app icons on Welcome\'s first step: back to the step, the icon kept.',
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

  /// `Start learning`
  String get welcome_story_continue {
    return Intl.message(
      'Start learning',
      name: 'welcome_story_continue',
      desc: 'Welcome\'s last step: the button at the end of the story of the Bazaar, into the app (plan 3.5).',
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

  /// `When the app crashes, it sends a crash report to Sentry so the fault can be fixed. To follow the app's health by version, it also tells Sentry when it opens and closes, how long it took to open and when it froze, with a random number for this installation. None of this holds your name, what you read or your quiz answers. The app masks personal details before they leave the device, and Sentry keeps no IP address. A problem you send under Report a problem goes to Sentry the same way.`
  String get privacy_crash {
    return Intl.message(
      'When the app crashes, it sends a crash report to Sentry so the fault can be fixed. To follow the app\'s health by version, it also tells Sentry when it opens and closes, how long it took to open and when it froze, with a random number for this installation. None of this holds your name, what you read or your quiz answers. The app masks personal details before they leave the device, and Sentry keeps no IP address. A problem you send under Report a problem goes to Sentry the same way.',
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

  /// `Report a problem`
  String get feedback_title {
    return Intl.message('Report a problem', name: 'feedback_title', desc: '', args: []);
  }

  /// `Write what went wrong. The report goes to Sentry with the app's version and the device's model and system, and with no name or email. The app masks emails and other personal details in it before it leaves the device.`
  String get feedback_intro {
    return Intl.message(
      'Write what went wrong. The report goes to Sentry with the app\'s version and the device\'s model and system, and with no name or email. The app masks emails and other personal details in it before it leaves the device.',
      name: 'feedback_intro',
      desc: '',
      args: [],
    );
  }

  /// `What happened`
  String get feedback_field {
    return Intl.message('What happened', name: 'feedback_field', desc: '', args: []);
  }

  /// `Send`
  String get feedback_send {
    return Intl.message('Send', name: 'feedback_send', desc: '', args: []);
  }

  /// `Sending`
  String get feedback_sending {
    return Intl.message('Sending', name: 'feedback_sending', desc: '', args: []);
  }

  /// `The report is sent.`
  String get feedback_sent {
    return Intl.message('The report is sent.', name: 'feedback_sent', desc: '', args: []);
  }

  /// `The report was not sent. Try again later.`
  String get feedback_failed {
    return Intl.message('The report was not sent. Try again later.', name: 'feedback_failed', desc: '', args: []);
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

  /// `The privacy note on the website`
  String get privacy_site_note {
    return Intl.message(
      'The privacy note on the website',
      name: 'privacy_site_note',
      desc: 'Link under Privacy to the site\'s privacy note, which covers the app too (web D138).',
      args: [],
    );
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

  /// `Skip`
  String get about_skip {
    return Intl.message(
      'Skip',
      name: 'about_skip',
      desc: 'The story film at the top, on the first launch: leaves the story for the language and track step.',
      args: [],
    );
  }

  /// `Close`
  String get about_close {
    return Intl.message(
      'Close',
      name: 'about_close',
      desc: 'The story film from Settings: its close button at the top and the button at its end, back to Settings.',
      args: [],
    );
  }

  /// `Next`
  String get about_next {
    return Intl.message(
      'Next',
      name: 'about_next',
      desc: 'The story film, for a screen reader: the far side of the screen, which goes on to the next screen.',
      args: [],
    );
  }

  /// `Previous`
  String get about_previous {
    return Intl.message(
      'Previous',
      name: 'about_previous',
      desc: 'The story film, for a screen reader: the near side of the screen, which goes back a screen.',
      args: [],
    );
  }

  /// `This module could not be read on this device. Try again, or restart the app.`
  String get reader_failed {
    return Intl.message(
      'This module could not be read on this device. Try again, or restart the app.',
      name: 'reader_failed',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get reader_retry {
    return Intl.message('Try again', name: 'reader_retry', desc: '', args: []);
  }

  /// `Pocket model`
  String get pocket_title {
    return Intl.message(
      'Pocket model',
      name: 'pocket_title',
      desc: 'Home\'s toy under Your path (plan 9.2): a tiny model the reader trains with tokens.',
      args: [],
    );
  }

  /// `A toy model that can talk nonsense.`
  String get pocket_lede {
    return Intl.message('A toy model that can talk nonsense.', name: 'pocket_lede', desc: '', args: []);
  }

  /// `Feed tokens`
  String get pocket_feed {
    return Intl.message('Feed tokens', name: 'pocket_feed', desc: '', args: []);
  }

  /// `Ask it`
  String get pocket_ask {
    return Intl.message('Ask it', name: 'pocket_ask', desc: '', args: []);
  }

  /// `Temperature`
  String get pocket_temperature {
    return Intl.message('Temperature', name: 'pocket_temperature', desc: '', args: []);
  }

  /// `Level {level}`
  String pocket_level(int level) {
    return Intl.message('Level $level', name: 'pocket_level', desc: '', args: [level]);
  }

  /// `{count, plural, =1{1 token} other{{count} tokens}}`
  String pocket_tokens(int count) {
    return Intl.plural(count, one: '1 token', other: '$count tokens', name: 'pocket_tokens', desc: '', args: [count]);
  }

  /// `{count} to level {level}`
  String pocket_to_next(int count, int level) {
    return Intl.message(
      '$count to level $level',
      name: 'pocket_to_next',
      desc: 'The tokens still to feed before the next level.',
      args: [count, level],
    );
  }

  /// `{count, plural, =1{knows 1 word} other{knows {count} words}}`
  String pocket_known(int count) {
    return Intl.plural(
      count,
      one: 'knows 1 word',
      other: 'knows $count words',
      name: 'pocket_known',
      desc: 'How many words the pocket model has read, after its tokens.',
      args: [count],
    );
  }

  /// `Fully trained`
  String get pocket_top {
    return Intl.message('Fully trained', name: 'pocket_top', desc: '', args: []);
  }

  /// `loss {value}`
  String pocket_loss(String value) {
    return Intl.message(
      'loss $value',
      name: 'pocket_loss',
      desc: 'The training loss, as a model\'s training prints it, small.',
      args: [value],
    );
  }

  /// `level`
  String get pocket_level_word {
    return Intl.message(
      'level',
      name: 'pocket_level_word',
      desc: 'The small word under the level number in its ring.',
      args: [],
    );
  }

  /// `Training loss`
  String get pocket_loss_title {
    return Intl.message(
      'Training loss',
      name: 'pocket_loss_title',
      desc: 'The heading of the pocket model\'s training curve.',
      args: [],
    );
  }

  /// `The curve starts with the first feed.`
  String get pocket_loss_empty {
    return Intl.message(
      'The curve starts with the first feed.',
      name: 'pocket_loss_empty',
      desc: 'In the training curve\'s place before the model is fed.',
      args: [],
    );
  }

  /// `New: it knows no words yet. Feed it some tokens.`
  String get pocket_status_newborn {
    return Intl.message(
      'New: it knows no words yet. Feed it some tokens.',
      name: 'pocket_status_newborn',
      desc: '',
      args: [],
    );
  }

  /// `Hungry: not fed for hours.`
  String get pocket_status_hungry {
    return Intl.message('Hungry: not fed for hours.', name: 'pocket_status_hungry', desc: '', args: []);
  }

  /// `Asleep. Tap it to wake it.`
  String get pocket_status_asleep {
    return Intl.message('Asleep. Tap it to wake it.', name: 'pocket_status_asleep', desc: '', args: []);
  }

  /// `Overfitted: it learnt the tokens by heart and repeats them. Let it rest a few seconds.`
  String get pocket_status_overfit {
    return Intl.message(
      'Overfitted: it learnt the tokens by heart and repeats them. Let it rest a few seconds.',
      name: 'pocket_status_overfit',
      desc: '',
      args: [],
    );
  }

  /// `Rested, and ready to learn again.`
  String get pocket_status_recovered {
    return Intl.message('Rested, and ready to learn again.', name: 'pocket_status_recovered', desc: '', args: []);
  }

  /// `Too hot: it hallucinates. Turn the temperature down.`
  String get pocket_status_hallucinating {
    return Intl.message(
      'Too hot: it hallucinates. Turn the temperature down.',
      name: 'pocket_status_hallucinating',
      desc: '',
      args: [],
    );
  }

  /// `Cold: it says its likeliest words, every time.`
  String get pocket_status_cold {
    return Intl.message(
      'Cold: it says its likeliest words, every time.',
      name: 'pocket_status_cold',
      desc: '',
      args: [],
    );
  }

  /// `Level {level}: it can say more now.`
  String pocket_status_level_up(int level) {
    return Intl.message('Level $level: it can say more now.', name: 'pocket_status_level_up', desc: '', args: [level]);
  }

  /// `hallucinating`
  String get pocket_hallucinating {
    return Intl.message(
      'hallucinating',
      name: 'pocket_hallucinating',
      desc: 'The tag on a speech bubble said while too hot.',
      args: [],
    );
  }

  /// `Pocket model, level {level}. Tap to pet it.`
  String pocket_stage_label(int level) {
    return Intl.message(
      'Pocket model, level $level. Tap to pet it.',
      name: 'pocket_stage_label',
      desc: '',
      args: [level],
    );
  }

  /// `It says: {words}`
  String pocket_says(String words) {
    return Intl.message('It says: $words', name: 'pocket_says', desc: '', args: [words]);
  }

  /// `Read a module you finished`
  String get pocket_read_module {
    return Intl.message(
      'Read a module you finished',
      name: 'pocket_read_module',
      desc: 'The pocket model\'s button that gives it a course module the reader completed to read.',
      args: [],
    );
  }

  /// `{count, plural, =1{1 finished module waiting} other{{count} finished modules waiting}}`
  String pocket_read_waiting(int count) {
    return Intl.plural(
      count,
      one: '1 finished module waiting',
      other: '$count finished modules waiting',
      name: 'pocket_read_waiting',
      desc: 'Under the read button, and on the round button for a screen reader: the completed modules the pocket model has not read.',
      args: [count],
    );
  }

  /// `Finish a module, and it can read it too.`
  String get pocket_read_none {
    return Intl.message(
      'Finish a module, and it can read it too.',
      name: 'pocket_read_none',
      desc: 'In the read button\'s place when no completed module is left for the pocket model to read.',
      args: [],
    );
  }

  /// `Start over`
  String get pocket_reset {
    return Intl.message(
      'Start over',
      name: 'pocket_reset',
      desc: 'The button that starts the pocket model again at level 0.',
      args: [],
    );
  }

  /// `Start the pocket model over?`
  String get pocket_reset_title {
    return Intl.message('Start the pocket model over?', name: 'pocket_reset_title', desc: '', args: []);
  }

  /// `It forgets every token it read and starts again at level 0. The course and its progress stay as they are.`
  String get pocket_reset_body {
    return Intl.message(
      'It forgets every token it read and starts again at level 0. The course and its progress stay as they are.',
      name: 'pocket_reset_body',
      desc: '',
      args: [],
    );
  }

  /// `Keep it`
  String get pocket_reset_keep {
    return Intl.message(
      'Keep it',
      name: 'pocket_reset_keep',
      desc: 'Closes the start-over dialog and keeps the pocket model as it is.',
      args: [],
    );
  }

  /// `Customize`
  String get settings_customize {
    return Intl.message(
      'Customize',
      name: 'settings_customize',
      desc: 'Settings\' section for the app icon, the pocket model\'s button and the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `Pocket model`
  String get settings_pocket_button {
    return Intl.message(
      'Pocket model',
      name: 'settings_pocket_button',
      desc: 'The switch that shows or hides the pocket model\'s round button on Home.',
      args: [],
    );
  }

  /// `Wardrobe`
  String get settings_robot {
    return Intl.message(
      'Wardrobe',
      name: 'settings_robot',
      desc: 'The row in Settings that opens the robot\'s wardrobe, and the wardrobe\'s title.',
      args: [],
    );
  }

  /// `Hat`
  String get wardrobe_hat {
    return Intl.message('Hat', name: 'wardrobe_hat', desc: 'The wardrobe\'s tab of hats.', args: []);
  }

  /// `Head`
  String get wardrobe_head {
    return Intl.message('Head', name: 'wardrobe_head', desc: 'The wardrobe\'s tab of heads.', args: []);
  }

  /// `Body`
  String get wardrobe_body {
    return Intl.message('Body', name: 'wardrobe_body', desc: 'The wardrobe\'s tab of bodies.', args: []);
  }

  /// `Each level of the pocket model unlocks something new to wear.`
  String get wardrobe_note {
    return Intl.message(
      'Each level of the pocket model unlocks something new to wear.',
      name: 'wardrobe_note',
      desc: 'Under the wardrobe\'s choices.',
      args: [],
    );
  }

  /// `Fez`
  String get outfit_hat_fez {
    return Intl.message('Fez', name: 'outfit_hat_fez', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Antenna`
  String get outfit_hat_antenna {
    return Intl.message('Antenna', name: 'outfit_hat_antenna', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Beanie`
  String get outfit_hat_beanie {
    return Intl.message('Beanie', name: 'outfit_hat_beanie', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Graduation cap`
  String get outfit_hat_mortarboard {
    return Intl.message(
      'Graduation cap',
      name: 'outfit_hat_mortarboard',
      desc: 'A name in the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `Turban`
  String get outfit_hat_turban {
    return Intl.message('Turban', name: 'outfit_hat_turban', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Wizard's hat`
  String get outfit_hat_wizard {
    return Intl.message('Wizard\'s hat', name: 'outfit_hat_wizard', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Top hat`
  String get outfit_hat_top_hat {
    return Intl.message('Top hat', name: 'outfit_hat_top_hat', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Crown`
  String get outfit_hat_crown {
    return Intl.message('Crown', name: 'outfit_hat_crown', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Classic screen`
  String get outfit_head_classic {
    return Intl.message(
      'Classic screen',
      name: 'outfit_head_classic',
      desc: 'A name in the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `Round head`
  String get outfit_head_dome {
    return Intl.message('Round head', name: 'outfit_head_dome', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Old television`
  String get outfit_head_tv {
    return Intl.message('Old television', name: 'outfit_head_tv', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Cat ears`
  String get outfit_head_ears {
    return Intl.message('Cat ears', name: 'outfit_head_ears', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Space helmet`
  String get outfit_head_visor {
    return Intl.message('Space helmet', name: 'outfit_head_visor', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Classic`
  String get outfit_body_classic {
    return Intl.message('Classic', name: 'outfit_body_classic', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Embroidered vest`
  String get outfit_body_vest {
    return Intl.message(
      'Embroidered vest',
      name: 'outfit_body_vest',
      desc: 'A name in the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `Hoodie`
  String get outfit_body_hoodie {
    return Intl.message('Hoodie', name: 'outfit_body_hoodie', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Lab coat`
  String get outfit_body_lab_coat {
    return Intl.message('Lab coat', name: 'outfit_body_lab_coat', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Kaftan`
  String get outfit_body_kaftan {
    return Intl.message('Kaftan', name: 'outfit_body_kaftan', desc: 'A name in the robot\'s wardrobe.', args: []);
  }

  /// `Suit and bow tie`
  String get outfit_body_suit {
    return Intl.message(
      'Suit and bow tie',
      name: 'outfit_body_suit',
      desc: 'A name in the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `Space suit`
  String get outfit_body_astronaut {
    return Intl.message(
      'Space suit',
      name: 'outfit_body_astronaut',
      desc: 'A name in the robot\'s wardrobe.',
      args: [],
    );
  }

  /// `{name}, worn`
  String wardrobe_item_worn(String name) {
    return Intl.message(
      '$name, worn',
      name: 'wardrobe_item_worn',
      desc: 'A wardrobe choice the robot wears, for a screen reader.',
      args: [name],
    );
  }

  /// `{name}, unlocks at level {level}`
  String wardrobe_item_locked(String name, int level) {
    return Intl.message(
      '$name, unlocks at level $level',
      name: 'wardrobe_item_locked',
      desc: 'A wardrobe choice not unlocked yet, for a screen reader.',
      args: [name, level],
    );
  }

  /// `The robot: {hat}, {head}, {body}`
  String wardrobe_preview(String hat, String head, String body) {
    return Intl.message(
      'The robot: $hat, $head, $body',
      name: 'wardrobe_preview',
      desc: 'The wardrobe\'s picture of the robot, for a screen reader.',
      args: [hat, head, body],
    );
  }

  /// `Level {level}. New in its wardrobe: {items}.`
  String pocket_status_unlocked(int level, String items) {
    return Intl.message(
      'Level $level. New in its wardrobe: $items.',
      name: 'pocket_status_unlocked',
      desc: 'The status line when a level unlocks something to wear.',
      args: [level, items],
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
